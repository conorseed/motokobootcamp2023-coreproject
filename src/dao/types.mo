import Principal "mo:base/Principal";
import List "mo:base/List";
import Map "vendor/map/Map";

/*

=======
KEY PRINCIPAL
=======
-- HashMap<proposal_id, votes>

Check if a user has voted on a proposal
   -- Look up votes by PRINCIPAL
   -- Filter votes by proposal_id
   
*/
module DaoTypes{
    public type Proposal = {
        timestamp: Int;
        proposer: Principal;
        payload: ProposalPayload;
        votes_yes: Nat;
        votes_no: Nat;
        status: ProposalStatus;
    };

    public type Vote = {
        voter: Principal;
        timestamp: Int;
        vote: Bool;
        power: Nat;
    };

    public type Votes = {
        votes: Map.Map<Nat, Vote>;
    };

    public type ProposalStatus = {
        #open;
        #executed;
        #failed: Text;
    };

    public type ProposalPayload = {
        #update_webpage : { message : Text };
        #update_config; // TODO Add Type
    };
    
}