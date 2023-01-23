/* CUSTOM IMPORTS */
import Dao "helpers";
import Map "vendor/map/Map";

/* BASE IMPORTS */
import Principal "mo:base/Principal";
import List "mo:base/List";
import Time "mo:base/Time";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";
import Error "mo:base/Error";
import Result "mo:base/Result";
import Cycles "mo:base/ExperimentalCycles";

shared ({ caller = creator }) actor class TheDao() {

    /* 
    ==========
    SETUP
    ==========
    */
    // Config
    stable var config: Dao.Config = {
        min_to_propose = 1;
        min_to_vote = 1;
        threshold_pass = 100;
        threshold_fail = 100;
        quadratic_voting = false;
        proposal_length = 1800;
        neuron_voting = false;
    };

    // Accounts
    stable var accounts = Map.new<Principal, Dao.Account>();
    stable var new_neuron_id = 1;

    // Proposals
    stable var proposals = Map.new<Nat, Dao.Proposal>();
    stable var new_proposal_id : Nat = 1;

    // Votes
    stable var votes = Map.new<Principal, Dao.Votes>();

    // heartbeat
    stable var heartbeat_last_run: Int = 0;

    // other vars
    let owner : Principal = creator;
    let { nhash; phash; bhash; } = Map;

    /* 
    ==========
    Proposals
    ==========
    */

    /*
     * Submit Proposal
     * @required: non-anonymous principal
     */
    public shared({caller}) func submit_proposal(payload: Dao.ProposalPayload, title: Text, description: Text) : async {#Ok : (Nat, Dao.Proposal); #Err : Text} {
        
        // Auth - No anonymous proposals
        if( Principal.isAnonymous(caller) == true ){
            return #Err("You must be logged in to submit a proposal");
        };
        
        // min_to_propose requirement
        var balance = await Dao.get_token_balance(caller);

        if( balance < config.min_to_propose ){
            return #Err("Proposal denied. You must have at least " # Nat.toText(config.min_to_propose) # "MB to Propose. Go get some: https://dpzjy-fyaaa-aaaah-abz7a-cai.ic0.app/");
        };

        // Prepare Data
        let id : Nat = new_proposal_id;
        let time = Time.now();
        let new_proposal : Dao.Proposal = {
            created = time;
            updated = time;
            proposer = caller;
            payload = payload;
            votes_yes = 0;
            votes_no = 0;
            status = #open;
            title = title;
            description = description;
        };
        
        // Create Proposal
        ignore Map.put<Nat, Dao.Proposal>(proposals, nhash, new_proposal_id, new_proposal);

        // After created
        new_proposal_id += 1;
        
        // Return proposal
        return #Ok((id, new_proposal));
    };

    /*
     * Vote on proposal
     * @required: non-anonymous principal
     */
    public shared({caller}) func vote(proposal_id : Nat, yes_or_no : Bool) : async {#Ok : (Nat, Dao.Proposal, Text); #Err : Text} {

        // Auth - No anonymous proposals
        if( Principal.isAnonymous(caller) == true ){
            return #Err("You must be logged in to vote");
        };

        // Get proposal
        var proposal = Map.get(proposals, nhash, proposal_id);

        switch(proposal) {

            // return error if no proposal
            case(null) { 
                return #Err("Proposal #" # Nat.toText(proposal_id) # " doesn't exist.");
             };


            case(?proposal) { 

                // If proposal is no longer open, it cannot be voted on
                switch(proposal.status) {
                    case(#executed) { 
                        return #Err("Proposal #" # Nat.toText(proposal_id) # " has been executed and can no longer be voted on.");
                    };
                    case(#failed(reason)) { 
                        return #Err("Proposal #" # Nat.toText(proposal_id) # " has failed and can no longer be voted on. Reason: " # reason );
                    };
                    case(#passed) { 
                        return #Err("Proposal #" # Nat.toText(proposal_id) # " has passed and can no longer be voted on.");
                    };
                    case(#expired) { 
                        return #Err("Proposal #" # Nat.toText(proposal_id) # " has expired and can no longer be voted on.");
                    };
                    case(#open) { };
                };

                // min_to_vote requirement
                var balance = await Dao.get_token_balance(caller);
               
                if( balance < config.min_to_vote ){
                    return #Err("You must have a minimum of " # Nat.toText(config.min_to_propose) # "MB to vote. Go get some: https://dpzjy-fyaaa-aaaah-abz7a-cai.ic0.app/");
                };

                // Only one vote per proposal per principle allowed
                // get votes made by caller
                var user_votes = Map.find<Principal, Dao.Votes>(votes, func(k,v){ k == caller });
                var proposal_vote: ?(Nat, Dao.Vote) = null; 
                switch(user_votes) {
                    case(?(principal, user_votes)) { 
                        proposal_vote := Map.find<Nat, Dao.Vote>(user_votes.votes, func(k,v){ k == proposal_id });
                    };
                    // user hasn't voted yet
                    case(null){};
                };
                // if user has already voted, return error
                switch(proposal_vote) {
                    case(?(proposal_id, vote)) { 
                        return #Err("You have already voted on Proposal #" # Nat.toText(proposal_id) # ". You cannot vote more than once on a proposal.");
                    };
                    // user hasn't voted yet
                    case(null){};
                };

                // calculate voting power
                let voting_power = switch(config.neuron_voting){
                    // if neuron voting
                    case(true){
                        // get account
                        var accountId : Principal = Dao.get_accountPrincipal(caller);
                        var account = Map.get(accounts, phash, accountId);
                        // get neurons
                        switch(account){
                            case(?account){
                                Dao.calculate_voting_power_neurons(account.neurons, config.quadratic_voting);
                            };
                            case(_){
                                0;
                            };
                        };
                        
                    };
                    // if token voting
                    case(false){
                        Dao.calculate_voting_power(balance, config.quadratic_voting);
                    };
                };
                

                // setup vars for new proposal
                var votes_yes = proposal.votes_yes;
                var votes_no = proposal.votes_no;

                // updated votes accordingly
                switch(yes_or_no) {
                    case(true) { 
                        votes_yes += voting_power;
                     };
                    case(false) { 
                        votes_no += voting_power;
                    };
                };

                // check status needs to be updated
                var status = proposal.status;
                if(votes_yes >= config.threshold_pass){
                    status := #passed;
                };
                if(votes_no >= config.threshold_fail){
                    status := #failed("Proposal got downvoted into oblivion.");
                };

                // prepare create vote
                let time = Time.now();
                let new_vote : Dao.Vote = {
                    voter = caller;
                    timestamp = time;
                    vote = yes_or_no;
                    power = voting_power;
                };

                // prepare update proposal
                let updated_proposal : Dao.Proposal = {
                    created = proposal.created;
                    updated = time;
                    proposer = proposal.proposer;
                    payload = proposal.payload;
                    votes_yes = votes_yes;
                    votes_no = votes_no;
                    status = status;
                    title = proposal.title;
                    description = proposal.description;
                };

                // store the updates
                // add vote to votes
                switch(user_votes) {
                    case(?(principal, user_votes)) { 
                        ignore Map.put<Nat, Dao.Vote>(user_votes.votes, nhash, proposal_id, new_vote);
                        ignore Map.put<Principal, Dao.Votes>(votes, phash, principal, user_votes);
                    };
                    // user hasn't voted yet so need to create them in the hashmap
                    case(null){
                        var user_votes : Dao.Votes = {
                            votes = Map.new<Nat, Dao.Vote>();
                        };
                        ignore Map.put<Nat, Dao.Vote>(user_votes.votes, nhash, proposal_id, new_vote);
                        ignore Map.put<Principal, Dao.Votes>(votes, phash, caller, user_votes);
                    };
                };
                
                // update proposal
                ignore Map.put<Nat, Dao.Proposal>(proposals, nhash, proposal_id, updated_proposal);

                // default response messages
                var response_message = switch(status) {
                    case(#passed) { 
                        "Congrats! Your vote tipped the scales. Proposal #" # Nat.toText(proposal_id) # " has passed and will be executed shortly.";
                     };
                    case(#failed(data)) { 
                        "Can you believe it? Your vote tipped the scales. Proposal #" # Nat.toText(proposal_id) # " has failed.";
                    };
                    case(_){
                        "Your vote has been processed. Thanks!";
                    };
                };

                // return the good news
                return #Ok(proposal_id, updated_proposal, response_message);

            };
        };

    };

    /*
     * Request a single proposal
     */
    public query func get_proposal(proposal_id : Nat) : async ?(Nat, Dao.Proposal) {
        Map.find<Nat, Dao.Proposal>(proposals, func(k,v){ k == proposal_id });
    };
    
    /*
     * Request all proposals
     */
    public query func get_all_proposals() : async [(Nat, Dao.Proposal)] {
        
        var proposals_buffer = Buffer.Buffer<(Nat, Dao.Proposal)>(0);
        
        for ((k,v) in Map.entries(proposals)) {
            proposals_buffer.add((k,v));
        };
        
        return Buffer.toArray<(Nat, Dao.Proposal)>(proposals_buffer);
    };

    /*
     * Request votes from principal
     */
    public query func get_votes_from_principal(principal: Principal) : async [(Nat, Dao.Vote)] {
        
        var user_votes = Map.find<Principal, Dao.Votes>(votes, func(k,v){ k == principal });
        
        switch(user_votes) {
            case(?(principal, user_votes)) { 
                var votes_buffer = Buffer.Buffer<(Nat, Dao.Vote)>(0);
        
                for ((k,v) in Map.entries(user_votes.votes)) {
                    votes_buffer.add((k,v));
                };
                
                return Buffer.toArray<(Nat, Dao.Vote)>(votes_buffer);
            };
            // user hasn't voted yet
            case(null){
                return [];
            };
        };
    };

    /*
     * Request votes from proposal_id
     */
    public query func get_votes_from_proposal_id(proposal_id: Nat) : async [(Nat, Dao.Vote)] {

        // Get proposal
        let proposal = Map.get(proposals, nhash, proposal_id);

        // return empty array if proposal doesn't exit
        switch(proposal) {
            case(null) { return []; };
            case(?proposal) {};
        };

        // Setup buffer to store votes
        var votes_buffer = Buffer.Buffer<(Nat, Dao.Vote)>(0);

        // iterate over hashmap to find all votes 
        for ((k,v) in Map.entries(votes)) {
            
            // see if user has voted on proposal_id
            var proposal_votes = Map.find<Nat, Dao.Vote>(v.votes, func(k,v){ k == proposal_id });

            switch(proposal_votes) {

                // push vote to buffer if exists
                case(?(proposal_id, vote)) { 
                    votes_buffer.add((proposal_id, vote));
                };
                // user hasn't voted for this proposal
                case(null){};
            };

        };

        return Buffer.toArray<(Nat, Dao.Vote)>(votes_buffer);

    };


    /* 
    ==========
    HELPERS
    ==========
    */

    /*
     * Request Dao Config
     */
    public query func get_config() : async Dao.Config {
        return config;
    };

    /*
     * Request Voting Power
     */
    public shared({caller}) func get_voting_power(principal : Principal) : async Int {

        let voting_power = switch(config.neuron_voting){
            // if neuron voting
            case(true){
                // get account
                var accountId : Principal = Dao.get_accountPrincipal(caller);
                var account = Map.get(accounts, phash, accountId);
                // get neurons
                switch(account){
                    case(?account){
                        Dao.calculate_voting_power_neurons(account.neurons, config.quadratic_voting);
                    };
                    case(_){
                        0;
                    };
                };
                
            };
            // if token voting
            case(false){
                var balance = await Dao.get_token_balance(principal);
                Dao.calculate_voting_power(balance, config.quadratic_voting);
            };
        };
    };

    /*
     * Request token balance for principal
     */
    public func get_token_balance(principal : Principal) : async Nat {
        return await Dao.get_token_balance(principal);
    };

    /*
     * Receive cycles
     */
    public func receive_cycles() : async Result.Result<Text, Text> {
        // get cycles sent
        let cycles = Cycles.available();
        // if no cycles then return error
        if(cycles == 0){
            return #err("No cycles in call.");
        };
        // otherwise, eat up them cycles
        ignore Cycles.accept(cycles);
        return #ok("Thanks for the cycles <3");
    };

    /*
     * Heartbeat
     */
    var heartbeat_lock : Bool = false;

    system func heartbeat() : async () {
        // get time
        let time = Time.now();
        let heartbeat_next_run = heartbeat_last_run + Dao.seconds_to_nanoseconds(60);

        // only run every 1 minute
        if(time > heartbeat_next_run and heartbeat_lock == false){
            // Lock this up
            heartbeat_lock := true;

            // Do things
            await execute_proposals();
            await expire_proposals();
            await update_neurons();

            // update heartbeat timer
            heartbeat_last_run := time;

            // unlock
            heartbeat_lock := false;
        };
        
    };


    /* 
    ==========
    Neurons
    ==========
    */
    
    /*
     * See account details
     */
    public shared({caller}) func my_account() : async {#Ok : (Principal, Dao.AccountPayload); #Err : Text}{
        
        // Auth - No anonymous proposals
        if( Principal.isAnonymous(caller) == true ){
            return #Err("You must be logged in to get your account");
        };

        // get account
        var accountId : Principal = Dao.get_accountPrincipal(caller);
        var account = Map.get(accounts, phash, accountId);

        switch(account){

            // account exists
            case(?account){
                return #Ok((accountId, Dao.create_account_payload(account)));
            };

            // no account, so set one up!
            case(null){
                
                // setup account
                let subaccount: Dao.Subaccount = Dao.principalToSubaccount(caller);
                let new_account : Dao.Account = {
                    subaccount = subaccount;
                    neurons = Map.new<Nat, Dao.Neuron>();
                };
                
                // update accounts
                ignore Map.put<Principal, Dao.Account>(accounts, phash, accountId, new_account);
                
                return #Ok((accountId, Dao.create_account_payload(new_account)));
            };

        };

    };
    
    /*
     * Create a neuron
     */
    var neuron_create_lock = Map.new<Principal, Bool>();
    public shared({caller}) func neuron_create(neuron_balance : Nat, dissolve_delay: Int) : async {#Ok : (Nat, Dao.Neuron); #Err : Text} {
        
        // Auth - No anonymous proposals
        if( Principal.isAnonymous(caller) == true ){
            return #Err("You must be logged in to get your account");
        };

        // get account id
        var accountId : Principal = Dao.get_accountPrincipal(caller);

        // check if locked
        var lock = Map.find<Principal, Bool>(neuron_create_lock, func(k,v){ v == true });
        switch(lock){
            case(?locked){
                return #Err("Transaction already in progress");
            };
            case(_){
                // lock it up
                ignore Map.put<Principal, Bool>(neuron_create_lock, phash, accountId, true);
            };
        };

        // get balance of subaccount
        let token_balance = await Dao.get_token_balance_subaccount(owner, caller);
        
        // doesn't have enough in account
        // or account doesn't exist yet
        if(token_balance < neuron_balance){
            // unlock
            ignore Map.put<Principal, Bool>(neuron_create_lock, phash, accountId, false);
            // return
            return #Err("You don't have enough MB in your DAO account to create a neuron of " # Nat.toText(neuron_balance) # ". Please transfer some MB to your DAO account on the dApp. Your current balance is: " # Nat.toText(token_balance));
        };

        // get account
        var account = Map.get(accounts, phash, accountId);

        switch(account){

            // account exists
            case(?account){
                // create neuron!
                let time = Time.now();
                let new_neuron: Dao.Neuron = {
                    created = time;
                    updated = time;
                    status = #locked;
                    balance = neuron_balance;
                    dissolve_delay = {
                        delay = dissolve_delay;
                        initiated = 0;
                    };
                };

                // add that thing
                let id = new_neuron_id;
                ignore Map.put<Nat,Dao.Neuron>(account.neurons, nhash, id, new_neuron);
                ignore Map.put<Principal, Dao.Account>(accounts, phash, accountId, account);
                new_neuron_id += 1;

                // unlock
                ignore Map.put<Principal, Bool>(neuron_create_lock, phash, accountId, false);
                
                return #Ok((id, new_neuron));
            };

            // this shouldn't ever happen
            case(null){
                // unlock
                ignore Map.put<Principal, Bool>(neuron_create_lock, phash, accountId, false);
                return #Err("You don't have a DAO account yet! Go to the Account page on the dApp to create one.");
            };

        };
    };

    /*
     * Begin dissolving a neuron
     */
    public shared({caller}) func neuron_dissolve(neuron_id: Nat) : async {#Ok : (Nat, Dao.Neuron); #Err : Text}{

        // Auth - No anonymous proposals
        if( Principal.isAnonymous(caller) == true ){
            return #Err("You must be logged in to dissolve a neuron");
        };

        // get account
        var accountId : Principal = Dao.get_accountPrincipal(caller);
        var account = Map.get(accounts, phash, accountId);

        //find neuron
        switch(account){

            case(?account){
                
                // get neuron
                let neuron: ?Dao.Neuron = Map.get(account.neurons, nhash, neuron_id);

                switch(neuron){
                    // neuron exists
                    case(?neuron){
                        // update neuron!
                        let time = Time.now();
                        let updated_neuron: Dao.Neuron = {
                            created = neuron.created;
                            updated = time;
                            status = #dissolving;
                            balance = neuron.balance;
                            dissolve_delay = {
                                delay = neuron.dissolve_delay.delay;
                                initiated = time;
                            }
                        };

                        // save stuff
                        ignore Map.put<Nat,Dao.Neuron>(account.neurons, nhash, neuron_id, updated_neuron);
                        ignore Map.put<Principal, Dao.Account>(accounts, phash, accountId, account);
                        
                        return #Ok((neuron_id, updated_neuron));
                    };
                    // no neuron
                    case(_){
                        return #Err("Neuron #" # Nat.toText(neuron_id) # " either doesn't exist or doesn't belong to you.");
                    }
                };

            };

            case(_){
                return #Err("You don't have a DAO account yet! Go to the Account page on the dApp to create one.");
            };

        };

        return #Err("");

    };

    /*
     * Update dissolve delay of #dissolving neurons
     */
    private func update_neurons() : async () {
        
        // loop over all accounts
        for((accountId, account) in Map.entries(accounts)) {
            
            // find dissolving neurons
            let dissolving = Map.filter<Nat, Dao.Neuron>(account.neurons, func(neuron_id, neuron) { neuron.status == #dissolving });

            // iterate over them
            for((neuron_id, neuron) in Map.entries(dissolving)){
                
                // setup vars
                let time: Int = Time.now();
                var dissolve_delay: Int = Dao.nanoseconds_to_seconds(
                    Dao.seconds_to_nanoseconds(neuron.dissolve_delay.delay) - (time - neuron.updated)
                );
                var status = neuron.status;
                var balance = neuron.balance;

                // check if has dissolved
                if( dissolve_delay <= 0 ){

                    // set to 0 to keep it tidy
                    dissolve_delay := 0;
                    // update status
                    status := #dissolved;
                    // do the refund
                    let transfer: Result.Result<Nat, Text> = await Dao.send_tokens(owner, accountId, Dao.principalToSubaccount(accountId), neuron.balance); 
                    
                    // check the refund 
                    switch(transfer){
                        // if it went through then update the balance
                        case(#ok(data)){
                            balance := 0;
                        };
                        // if it didn't go through then leave balance as is
                        case(#err(data)){}
                    };
                };

                // update neuron!
                let updated_neuron: Dao.Neuron = {
                    created = neuron.created;
                    updated = time;
                    status = status;
                    balance = balance;
                    dissolve_delay = {
                        delay = dissolve_delay;
                        initiated = neuron.dissolve_delay.initiated;
                    }
                };

                // save stuff
                ignore Map.put<Nat,Dao.Neuron>(account.neurons, nhash, neuron_id, updated_neuron);
                ignore Map.put<Principal, Dao.Account>(accounts, phash, accountId, account);
            }
            
        };
       
    };

    /* 
    ==========
    Utils
    ==========
    */

    /*
     * Execute #passed proposals
     */
    private func execute_proposals() : async (){
        // get all passed proposals
        let passed = Map.filter<Nat, Dao.Proposal>(proposals, func(proposal_id, proposal) { proposal.status == #passed }); 

        // iterate over them all and execute payload
        for ((proposal_id, proposal) in Map.entries(passed)) {
          
            var result: {#Ok; #Err : Text} = #Err("Something went wrong during execution of proposal.");

            switch(proposal.payload) {

                // If updating the message...
                case(#update_webpage(data)) { 
                    let response = await Dao.update_webpage(data.message);
                    // if call doesn't fail 
                    if(response == true){
                        result := #Ok;
                    };
                    
                };

                // if updating Dao config...
                case(#update_config(data)) {
                    // create new config and update
                    let new_config = Dao.create_new_config(config, data);
                    config := new_config;

                    result := #Ok;
                };
            };


            // check result and update proposal
            let time = Time.now();
            let updated_proposal : Dao.Proposal = switch(result){
                case(#Ok){

                    // setup updated proposal
                    {
                        created = proposal.created;
                        updated = time;
                        proposer = proposal.proposer;
                        payload = proposal.payload;
                        votes_yes = proposal.votes_yes;
                        votes_no = proposal.votes_no;
                        title = proposal.title;
                        description = proposal.description;
                        status = #executed;
                    };
                };

                case(#Err(reason)){
                    {
                        created = proposal.created;
                        updated = time;
                        proposer = proposal.proposer;
                        payload = proposal.payload;
                        votes_yes = proposal.votes_yes;
                        votes_no = proposal.votes_no;
                        title = proposal.title;
                        description = proposal.description;
                        status = #failed(reason);
                    };
                };
            };

            // update proposal
            ignore Map.put<Nat, Dao.Proposal>(proposals, nhash, proposal_id, updated_proposal);
        };

    };

    /*
     * Expire #open proposals passed config.proposal_length
     */
    private func expire_proposals() : async  () {
        // get open proposals
        let open = Map.filter<Nat, Dao.Proposal>(proposals, func(proposal_id, proposal) { proposal.status == #open }); 

        // get vars
        let time: Int = Time.now();
        let proposal_length: Int = Dao.seconds_to_nanoseconds(config.proposal_length);

        // iterate over them all and check if expired
        for ((proposal_id, proposal) in Map.entries(open)) {

            // calculate expiry time
            let proposal_expires = proposal.created + proposal_length;
            
            // check if time is after expiry
            if( proposal_expires <= time ){

                // then expire it
                let updated_proposal = {
                    created = proposal.created;
                    updated = time;
                    proposer = proposal.proposer;
                    payload = proposal.payload;
                    votes_yes = proposal.votes_yes;
                    votes_no = proposal.votes_no;
                    title = proposal.title;
                    description = proposal.description;
                    status = #expired;
                };

                // update proposal
                ignore Map.put<Nat, Dao.Proposal>(proposals, nhash, proposal_id, updated_proposal);
            }

        };
    };
};