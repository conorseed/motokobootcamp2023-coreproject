import Principal "mo:base/Principal";
import List "mo:base/List";
import Map "vendor/map/Map";

module DaoHelpers{

    /* 
    ==========
    VARS
    ==========
    */
    public let webpage : actor {
        update_message: (Text) -> async ();
        } = actor ("rno2w-sqaaa-aaaaa-aaacq-cai");
    // local: rno2w-sqaaa-aaaaa-aaacq-cai
    // ic: zrm7a-2yaaa-aaaan-qc2ea-cai

    /* 
    ==========
    TYPES
    ==========
    */

    public type Config = {
        min_to_propose: Nat;
        min_to_vote: Nat;
        threshold_pass: Nat;
        threshold_fail: Nat;
        quadratic_voting: Bool;
    };

    public type ConfigPayload = {
        min_to_propose: ?Nat;
        min_to_vote: ?Nat;
        threshold_pass: ?Nat;
        threshold_fail: ?Nat;
        quadratic_voting: ?Bool;
    };

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
        #update_config: ConfigPayload;
    };


    /* 
    ==========
    Helpers
    ==========
    */

    // update webpage call
    public func update_webpage(message : Text) : async Bool {
        try{
            await webpage.update_message(message);
            return true;
        } catch (e){
            return false;
        }
    };

    // create new config
    // go through each setting of data payload and update if not null
    public func create_new_config(current_config: Config, data : ConfigPayload) : Config {

        let min_to_propose = switch(data.min_to_propose) {
            case(?min_to_propose) min_to_propose;
            case(null) current_config.min_to_propose ;
        };

        let min_to_vote = switch(data.min_to_vote) {
            case(?min_to_vote) min_to_vote;
            case(null) current_config.min_to_vote ;
        };

        let threshold_pass = switch(data.threshold_pass) {
            case(?threshold_pass) threshold_pass;
            case(null) current_config.threshold_pass ;
        };

        let threshold_fail = switch(data.threshold_fail) {
            case(?threshold_fail) threshold_fail;
            case(null) current_config.threshold_fail ;
        };

        let quadratic_voting = switch(data.quadratic_voting) {
            case(?quadratic_voting) quadratic_voting;
            case(null) current_config.quadratic_voting ;
        };

        let new_config: Config = {
            min_to_propose = min_to_propose;
            min_to_vote =  min_to_vote;
            threshold_pass = threshold_pass;
            threshold_fail = threshold_fail;
            quadratic_voting = quadratic_voting;
        };

        return new_config;
    };
    
}