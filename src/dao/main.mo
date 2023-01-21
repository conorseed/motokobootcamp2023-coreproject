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

shared ({ caller = creator }) actor class TheDao() {

    /* 
    ==========
    SETUP
    ==========
    */
    // Proposals
    stable var proposals = Map.new<Nat, Dao.Proposal>();
    stable var new_proposal_id : Nat = 1;

    // Votes
    stable var votes = Map.new<Principal, Dao.Votes>();

    // Config
    stable var config: Dao.Config = {
        min_to_propose = 1;
        min_to_vote = 1;
        threshold_pass = 100;
        threshold_fail = 100;
        quadratic_voting = false;
        proposal_length = 1800;
    };

    // heartbeat
    stable var heartbeat_last_run: Int = 0;

    // other vars
    let { nhash; phash; } = Map;
    let owner : Principal = creator;

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
            //return #Err("You must be logged in to submit a proposal");
        };
        
        // min_to_propose requirement
        var balance = await Dao.get_token_balance(caller);
        // TODO remove for production
        if( Principal.isAnonymous(caller) == true ){
            balance := 100
        };
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
            //return #Err("You must be logged in to submit a proposal");
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
                // TODO
                // remove for production
                if( Principal.isAnonymous(caller) == true ){
                    balance := 100
                };
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
                let voting_power = Dao.calculate_voting_power(balance, config.quadratic_voting);

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
    public shared({caller}) func get_voting_power(principal : Principal) : async Nat {
        var balance = await Dao.get_token_balance(principal);
        // TODO remove for production
        if( Principal.isAnonymous(caller) == true ){
            balance := 100
        };
        return Dao.calculate_voting_power(balance, config.quadratic_voting);
    };

    /*
     * Request token balance for principal
     */
    public func get_token_balance(principal : Principal) : async Nat {
        return await Dao.get_token_balance(principal);
    };

    /*
     * Heartbeat
     */
     // TODO
     // auto execute proposals once passed
     // auto expire proposals
    system func heartbeat() : async () {
        // get time
        let time = Time.now();
        let heartbeat_next_run = heartbeat_last_run + Dao.seconds_to_nanoseconds(60);

        // only run every 1 minute
        if(time > heartbeat_next_run){
            
            // Do things
            await execute_proposals();
            await expire_proposals();

            // update heartbeat timer
            heartbeat_last_run := time;
        };
        
    };


    /* 
    ==========
    Neurons
    ==========
    */
    // TODO
    // createNeuron
    // dissolveNeuron 

    /* 
    ==========
    Certified Data
    ==========
    */
    // TODO

    // TODO
    // Blackhole?


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