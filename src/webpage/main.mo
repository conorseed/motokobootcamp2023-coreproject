import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Http "http";
import Certification "certification";

actor {

    stable var body_text : Text = "Hello there. General Kenobi.";

    private func removeQuery(str: Text): Text {
        switch(Text.split(str, #char '?').next()) {
            case(null) {
                return str;
            };
            case(?url) { 
                return url;
            };
        };
    };

    public query func http_request(req: Http.HttpRequest): async (Http.HttpResponse) {

        let path = removeQuery(req.url);
        
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

    private func main_page(): Blob {
        return Text.encodeUtf8 (
            "Message from the canister:\n" #
            body_text
        )
    };

    /*
     * Certification Stuff
     */
    system func postupgrade() {
        Certification.update_asset_hash(main_page());
    };

    // https://gist.github.com/nomeata/f325fcd2a6692df06e38adedf9ca1877 
    // https://github.com/dfinity/examples/blob/master/motoko/cert-var/src/cert_var/main.mo

    public shared func leave_message(msg : Text) : async () {
        body_text := msg;
        Certification.update_asset_hash(main_page());
    };
};