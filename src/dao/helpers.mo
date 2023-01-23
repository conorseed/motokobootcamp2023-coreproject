import Map "vendor/map/Map";
import SHA224 "vendor/accounts/SHA224";
import CRC32 "vendor/accounts/CRC32";

import Principal "mo:base/Principal";
import List "mo:base/List";
import Int "mo:base/Int";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Buffer "mo:base/Buffer";
import Blob "mo:base/Blob";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Result "mo:base/Result";
import Float "mo:base/Float";
import Time "mo:base/Time";

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
        icrc1_transfer : TokenTransferArgs -> async TokenResult;
        mint : shared TokenMintArgs -> async TokenResult;
        } = actor ("db3eq-6iaaa-aaaah-abz6a-cai");

    /* 
    ==========
    TYPES
    ==========
    */

    public type Config = {
        min_to_propose: Nat; // Minimum MB required to propose
        min_to_vote: Nat; // Minimum MB required to vote
        threshold_pass: Nat; // proposal will pass if votes_yes reaches this threshold
        threshold_fail: Nat; // proposal will fail if votes_no reaches this threshold
        quadratic_voting: Bool; // when enabled voting power is equal to the square root of their MB token balance
        proposal_length: Int; // length of time in seconds for a proposal to pass, otherwise it will auto fail
        neuron_voting: Bool; // switch the Dao to voting with Neurons
    };

    public type ConfigPayload = {
        min_to_propose: ?Nat;
        min_to_vote: ?Nat;
        threshold_pass: ?Nat;
        threshold_fail: ?Nat;
        quadratic_voting: ?Bool;
        proposal_length: ?Int;
        neuron_voting: ?Bool;
    };

    public type Proposal = {
        created: Int; // timestamp from Time.now() of when created
        updated: Int; // timestamp from Time.now() of last update to proposal
        proposer: Principal; // principal of proposer
        payload: ProposalPayload; // what the proposal will execute
        votes_yes: Int;
        votes_no: Int;
        status: ProposalStatus;
        title: Text;
        description: Text;
    };

    public type Vote = {
        voter: Principal; // include this here too, so that it's included when returning get_votes_from_proposal_id
        timestamp: Int; // timestamp from Time.now() of when created
        vote: Bool;
        power: Int;
    };

    public type Votes = {
        votes: Map.Map<Nat, Vote>;
    };

    public type ProposalStatus = {
        #open;
        #passed;
        #executed;
        #failed: Text;
        #expired;
    };

    public type ProposalPayload = {
        #update_webpage : { message : Text };
        #update_config: ConfigPayload;
    };

    public type Account = {
        subaccount: Subaccount;
        neurons: Map.Map<Nat, Neuron>;
    };

    public type AccountPayload = {
        subaccount: Subaccount;
        neurons: [(Nat, Neuron)];
    };

    public type Neuron = {
        created: Int; // timestamp from Time.now() of when created
        updated: Int; // timestamp from Time.now() of when last updated
        status: NeuronStatus; //status of neuron
        balance: Nat; // number of MB tokens deposited
        dissolve_delay: NeuronDissolveDelay;
    };

    public type NeuronStatus = {
        #locked;
        #dissolving;
        #dissolved;
    };

    public type NeuronDissolveDelay = {
        delay: Int; // length of time in seconds for neuron to dissolve
        initiated: Int; // timestamp from Time.now() of when dissolving was initiated
    };

    public type Subaccount = Blob;
    public type AccountIdentifier = Blob;

    public type TokenTransferArgs = {
        to : { owner : Principal; subaccount : ?[Nat8] };
        fee : ?Nat;
        memo : ?[Nat8];
        from_subaccount : ?Subaccount;
        created_at_time : ?Nat64;
        amount : Nat;
    };

    public type TokenMintArgs = {
        to : { owner : Principal; subaccount : ?[Nat8] };
        memo : ?[Nat8];
        created_at_time : ?Nat64;
        amount : Nat;
    };

    public type TokenResult = { #ok : Nat; #err : TokenTransferError };

    public type TokenTransferError = {
        #GenericError : { message : Text; error_code : Nat };
        #TemporarilyUnavailable;
        #BadBurn : { min_burn_amount : Nat };
        #Duplicate : { duplicate_of : Nat };
        #BadFee : { expected_fee : Nat };
        #CreatedInFuture : { ledger_time : Nat64 };
        #TooOld;
        #InsufficientFunds : { balance : Nat };
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

        let proposal_length = switch(data.proposal_length) {
            case(?proposal_length) proposal_length;
            case(null) current_config.proposal_length ;
        };

        let neuron_voting = switch(data.neuron_voting) {
            case(?neuron_voting) neuron_voting;
            case(null) current_config.neuron_voting ;
        };

        let new_config: Config = {
            min_to_propose = min_to_propose;
            min_to_vote =  min_to_vote;
            threshold_pass = threshold_pass;
            threshold_fail = threshold_fail;
            quadratic_voting = quadratic_voting;
            proposal_length = proposal_length;
            neuron_voting = neuron_voting;
        };

        return new_config;
    };

    // get token balance for principal
    public func get_token_balance(principal : Principal) : async Nat {
        var balance = await mb_token.icrc1_balance_of({ owner = principal; subaccount = null; });
        return balance / 100000000;
    };

    // get token balance for subaccount
    public func get_token_balance_subaccount(owner: Principal, caller : Principal) : async Nat {
        var balance = await mb_token.icrc1_balance_of({ owner = owner; subaccount = ?Blob.toArray(principalToSubaccount(caller)); });
        return balance / 100000000;
    };

    // send tokens from subaccount
    public func send_tokens(owner: Principal, caller: Principal, subaccount : Subaccount, amount: Nat) : async Result.Result<Nat, Text> {
        
        // check canister balance
        let canisterBalance = await get_token_balance(owner);
        let fee = 1000000;

        // mint more tokens for canister if needed
        if(canisterBalance < fee){

            let mint = await mb_token.mint({
                to = { owner = caller; subaccount = ?Blob.toArray(subaccount); };
                memo = null;
                created_at_time = null;
                amount = 100 * 100000000;
            });
            switch(mint){
                case(#err(error)){
                    return #err("Cansiter doesn't have enough tokens")
                };
                // do nothing
                case(#ok(data)){}
            }
        };

        // setup transaction
        let amountCalc = amount * 100000000;
        // send it
        let result = await mb_token.icrc1_transfer({
            to = { owner = caller; subaccount = null; };
            fee = ?fee;
            memo = null;
            from_subaccount = ?subaccount;
            created_at_time = null;
            amount = amountCalc;
        });
        // check result
        switch(result){
            case(#ok(data)){
                return #ok(data);
            };
            case(_){
                return #err("");
            };
        };
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
     * calculate voting power for neurons
     *
    Voting power of a neuron is counted as follows:
    AMOUNT MB TOKENS * DISSOLVE DELAY BONUS * AGE BONUS where:
    Dissolve delay bonus: The bonuses scale linearly, from 6 months which grants a 1.06x voting power bonus, to 8 years which grants a 2x voting power bonus
    Age bonus: the maximum bonus is attained for 4 years and grants a 1.25x bonus, multiplicative with any other bonuses. The bonuses for durations between 0 seconds and 4 years scale linearly between.
    */
    
    public func calculate_voting_power_neurons(neurons: Map.Map<Nat, Neuron>, quadratic_voting: Bool) : Int {
        
        var power: Float = 0;

        // iterate over neurons and calc the power!
        for((neuron_id, neuron) in Map.entries(neurons)) {
            
            // calc dissolve delay bonus
            var dissolve_delay_months = seconds_to_months(neuron.dissolve_delay.delay);
            var dissolve_delay_bonus : Float = 0;

            // if greater than 6 months and less than 8 years
            if(dissolve_delay_months >= 6 and dissolve_delay_months < 96){
                dissolve_delay_bonus := 1 + (0.01 * Float.fromInt(dissolve_delay_months));
            };
            // if over 8 years
            if(dissolve_delay_months >= 96){
                dissolve_delay_bonus := 2;
            };

            // calc age bonus
            var age_bonus: Float = 1;
            var bonus_per_second = 0.000000001980546;
            var seconds_since_created = nanoseconds_to_seconds(Time.now() - neuron.created);
            var months_since_created = seconds_to_months(seconds_since_created);

            // over 4 years old
            if(months_since_created >= 48){
                age_bonus := 1.25;
            }
            // otherwise do the scaling
            else{
                age_bonus := Float.fromInt(seconds_since_created) * bonus_per_second;
            };
            
            // add to the power!
            power += Float.fromInt(neuron.balance) * dissolve_delay_bonus * age_bonus;
        };

        // check if quadratic enabled
        switch(quadratic_voting){
            case(false){
                return Float.toInt(power);
            };

            case(true){
                return Float.toInt(Float.sqrt(power));
            };
        };
        
    };

    // convert seconds to nanoseconds
    public func seconds_to_nanoseconds(time: Int) : Int{
        return time * 1000000000;
    };

    // convert seconds to nanoseconds
    public func nanoseconds_to_seconds(time: Int) : Int{
        return time / 1000000000;
    };

    // convert seconds to nanoseconds
    public func seconds_to_months(time: Int) : Int{
        return time / 2629746;
    };

    // convert map to array
    public func map_to_array<K, V>(map: Map.Map<K,V>) : [(K,V)] {
        var buffer = Buffer.Buffer<(K,V)>(0);
        
        for ((k,v) in Map.entries(map)) {
            buffer.add((k,v));
        };
        
        return Buffer.toArray<(K,V)>(buffer);
    };

    // create payload to return account
    public func create_account_payload(account: Account) : AccountPayload{
        return {
            subaccount = account.subaccount;
            neurons = map_to_array(account.neurons);
        };
    };

    /* 
    ==========
    Utils
    ==========
    */
    // calculate the square root of a nat
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

    // convert principal to subaccount
    public func principalToSubaccount(principal: Principal) : Blob {
        let idHash = SHA224.Digest();
        idHash.write(Blob.toArray(Principal.toBlob(principal)));
        let hashSum = idHash.sum();
        let crc32Bytes = beBytes(CRC32.ofArray(hashSum));
        let buf = Buffer.Buffer<Nat8>(32);
        let blob = Blob.fromArray(Array.append(crc32Bytes, hashSum));

        return blob;
    };

    // convert to bytes
    private func beBytes(n : Nat32) : [Nat8] {
        func byte(n : Nat32) : Nat8 {
        Nat8.fromNat(Nat32.toNat(n & 0xff))
        };
        [byte(n >> 24), byte(n >> 16), byte(n >> 8), byte(n)]
    }; 

    // create account identifier
    public func accountIdentifier(principal: Principal, subaccount: Subaccount) : AccountIdentifier {
        let hash = SHA224.Digest();
        hash.write([0x0A]);
        hash.write(Blob.toArray(Text.encodeUtf8("account-id")));
        hash.write(Blob.toArray(Principal.toBlob(principal)));
        hash.write(Blob.toArray(subaccount));
        let hashSum = hash.sum();
        let crc32Bytes = beBytes(CRC32.ofArray(hashSum));
        Blob.fromArray(Array.append(crc32Bytes, hashSum))
    };

    // get an accountId Principal from main principal
    public func get_accountPrincipal(principal: Principal) : Principal {
        var subaccount : Subaccount = principalToSubaccount(principal);
        return Principal.fromBlob(accountIdentifier(principal, subaccount));
    };
    
}