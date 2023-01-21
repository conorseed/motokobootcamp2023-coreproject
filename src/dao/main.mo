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
    };

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
    public shared({caller}) func submit_proposal(payload: Dao.ProposalPayload) : async {#Ok : (Nat, Dao.Proposal); #Err : Text} {
        
        // Auth - No anonymous proposals
        if( Principal.isAnonymous(caller) == true ){
            //return #Err("You must be logged in to submit a proposal");
        };
        
        // TODO
        // min_to_propose requirement

        // Prepare Data
        let id : Nat = new_proposal_id;
        let new_proposal : Dao.Proposal = {
            timestamp = Time.now();
            proposer = caller;
            payload = payload;
            votes_yes = 0;
            votes_no = 0;
            status = #open;
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
                        return #Err("Proposal #" # Nat.toText(proposal_id) # " has passed and can no longer be voted on.");
                    };
                    case(#failed(message: Text)) { 
                        return #Err("Proposal #" # Nat.toText(proposal_id) # " has failed and can no longer be voted on. Reason: " # message );
                    };
                    case(#open) { };
                };

                // TODO
                // min_to_vote requirement
                // return #Err("You must have a minimum of " # Nat.toText(config.min_to_vote) # " MB to vote.");

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

                // TODO
                // calculate voting power
                let voting_power = 100;

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
                    status := #executed;
                };
                if(votes_no >= config.threshold_fail){
                    status := #failed("Proposal got downvoted into oblivion.");
                };

                // prepare create vote
                let new_vote : Dao.Vote = {
                    voter = caller;
                    timestamp = Time.now();
                    vote = yes_or_no;
                    power = voting_power;
                };

                // prepare update proposal
                let updated_proposal : Dao.Proposal = {
                    timestamp = proposal.timestamp;
                    proposer = proposal.proposer;
                    payload = proposal.payload;
                    votes_yes = votes_yes;
                    votes_no = votes_no;
                    status = status;
                };


                // if status is not #executed, then there's nothing else to do but return!
                var response_message = "Your vote has been processed. Thanks!";

                // if status moves to #executed, do the calls
                if(status == #executed){

                    switch(proposal.payload) {

                        // If updating the message...
                        case(#update_webpage(data)) { 
                            let response = await Dao.update_webpage(data.message);
                            // if call fails
                            if(response == false){
                                throw Error.reject("Something went wrong during execution of proposal.");
                            };
                            // otherwise all is well!
                            response_message := "Your vote tipped the scales. Proposal #" # Nat.toText(proposal_id) #
                                    " has been executed. Webpage message now reads: \"" # data.message # "\".";
                            
                        };

                        // if updating Dao config...
                        case(#update_config(data)) {
                            // create new config and update
                            let new_config = Dao.create_new_config(config, data);
                            config := new_config;

                            response_message := "Your vote tipped the scales. Proposal #" # Nat.toText(proposal_id) #
                                    " has been executed. Dao config has been updated.";
                        };
                    };
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
    CONFIG
    ==========
    */
    /*
     * Request Dao Config
     */
    public query func get_config() : async Dao.Config {
        return config;
    };


    /* 
    ==========
    Neurons
    ==========
    */
    // TODO
    // createNeuron
    // dissolveNeuron 
};