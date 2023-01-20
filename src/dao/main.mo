/* CUSTOM IMPORTS */
import Dao "types";
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

actor {

    /* 
    ==========
    STABLE VARS
    ==========
    */
    let { nhash; phash; } = Map;

    // Proposals
    //var proposals = HashMap.HashMap<Nat, Dao.Proposal>(0, Nat.equal, Hash.hash);
    var proposals = Map.new<Nat, Dao.Proposal>();
    var new_proposal_id : Nat = 1;

    // Votes
    var votes = Map.new<Principal, Dao.Votes>();

    // Config
    var config = {
        min_to_propose: Nat = 1;
        min_to_vote: Nat = 1;
        threshold_pass: Nat = 100;
        threshold_fail: Nat = 100;
        quadratic_voting: Bool = false;
    };

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
        //proposals.put(new_proposal_id, new_proposal);
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
    public shared({caller}) func vote(proposal_id : Nat, yes_or_no : Bool) : async {#Ok : (Nat, Dao.Proposal); #Err : Text} {

        // Auth - No anonymous proposals
        if( Principal.isAnonymous(caller) == true ){
            //return #Err("You must be logged in to submit a proposal");
        };

        // Get proposal
        //let proposal = proposals.get(proposal_id);
        let proposal = Map.get(proposals, nhash, proposal_id);

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
                //let user_votes = List.find<Dao.Vote>(proposal.votes_list, func vote = vote.id == caller);
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
                    timestamp = Time.now();
                    vote = yes_or_no;
                    power = voting_power;
                };

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


                // prepare update proposal
                let updated_proposal : Dao.Proposal = {
                    timestamp = proposal.timestamp;
                    proposer = proposal.proposer;
                    payload = proposal.payload;
                    votes_yes = votes_yes;
                    votes_no = votes_no;
                    status = status;
                };

                // update proposal
                //proposals.put(proposal_id, updated_proposal);
                ignore Map.put<Nat, Dao.Proposal>(proposals, nhash, proposal_id, updated_proposal);

                // TODO
                // if status moves to #executed, do the calls


                // return ok!
                return #Ok((proposal_id, updated_proposal));

            };
        };
    };

    /*
     * Request a single proposal
     */
    public query func get_proposal(proposal_id : Nat) : async ?(Nat, Dao.Proposal) {
        //let proposal = proposals.get(proposal_id);
        //return (proposal_id, proposal);
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
     * Request all votes
     */
    public query func get_votes(principal: Principal) : async [(Nat, Dao.Vote)] {
        
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
    ==========
    Neurons
    ==========
    */
    // TODO
    // createNeuron
    // dissolveNeuron 
};