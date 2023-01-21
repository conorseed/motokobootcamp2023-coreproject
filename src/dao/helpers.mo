import Principal "mo:base/Principal";
import List "mo:base/List";
import Map "vendor/map/Map";
import Int "mo:base/Int";

module DaoHelpers{

    /* 
    ==========
    VARS
    ==========
    */
    let webpage : actor {
        update_message: (Text) -> async ();
        } = actor ("zrm7a-2yaaa-aaaan-qc2ea-cai");
    // local: rno2w-sqaaa-aaaaa-aaacq-cai
    // ic: zrm7a-2yaaa-aaaan-qc2ea-cai

    let mb_token : actor {
        icrc1_balance_of : { owner : Principal; subaccount : ?[Nat8] } -> async Nat;
        } = actor ("db3eq-6iaaa-aaaah-abz6a-cai");

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

    // TODO
    // Add in Title, Description, Expiry
    public type Proposal = {
        created: Int;
        updated: Int;
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
        #passed;
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

    // get token balance for principal
    public func get_token_balance(principal : Principal) : async Nat {
        var balance = await mb_token.icrc1_balance_of({ owner = principal; subaccount = null; });
        return balance / 100000000;
    };

    // calculate voting power
    // for non neuron system
    public func calculate_voting_power(balance: Nat, quadratic_voting: Bool) : Nat {
        
        switch(quadratic_voting){
            case(false){
                return balance;
            };

            case(true){
                return sqrt(balance);
            };
        };
        
    };


    /* 
    ==========
    Utils
    ==========
    */
    private func sqrt(x : Nat) : Nat {
        if (x == 0) {
           return 0;
        };

        var pre : Int = 0;
        var cur : Int = 1;

        loop {
            pre := cur;
            cur := (cur + x/cur)/2;

            if (Int.abs(cur - pre) <= 1) {
                return Int.abs(cur);
            };
        } while(true);

        Int.abs(cur);
    };
    
}