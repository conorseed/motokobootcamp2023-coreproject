// Custom imports
import Http "http";
import Certification "certification";

// Base imports
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Error "mo:base/Error";
import Debug "mo:base/Debug";
import Result "mo:base/Result";
import Cycles "mo:base/ExperimentalCycles";

shared ({ caller = creator }) actor class Webpage() {

    var owner: Principal = creator;

    /* 
    ==========
    Setup
    ==========
    */
    stable var body_text : Text = "Hello there. General Kenobi.";
    var dao: Principal = Principal.fromText("zwnzu-xaaaa-aaaan-qc2eq-cai");

    /* 
    ==========
    Update the message
    ==========
    */
    public shared({ caller }) func update_message(message : Text) : async () {
        // only dao can update message
        if(caller != dao){
            throw Error.reject("Only the DAO can update the message here." );
        };

        // Otherwise update message
        body_text := message;
        Certification.update_asset_hash(main_page());
    };

    /* 
    ==========
    Receive cycles
    ==========
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
    ==========
    SERVE HTTP
    ==========
    */
    public query func http_request(req: Http.HttpRequest): async (Http.HttpResponse) {

        let path = Http.removeQuery(req.url);
        
        if(path == "/") {
            return {
                body = main_page();
                headers = [("content-type", "text/plain"), Certification.certification_header(main_page())];
                //headers = [];
                status_code = 200;
                streaming_strategy = null;
            };
        };


        return {
            body = Text.encodeUtf8("404 Not found :" # path);
            headers = [];
            status_code = 404;
            streaming_strategy = null;
        };
    };


    // Output html
    private func main_page(): Blob {
        return Text.encodeUtf8 (
            body_text # 
            "\n\n\nThe above message is controlled by a DAO. Come join the fun: https://z7osi-biaaa-aaaan-qc2fa-cai.ic0.app/"
        )
    };

    /* 
    ==========
    Certification Stuff
    https://gist.github.com/nomeata/f325fcd2a6692df06e38adedf9ca1877
    ==========
    */
    system func postupgrade() {
        Certification.update_asset_hash(main_page());
    };

};