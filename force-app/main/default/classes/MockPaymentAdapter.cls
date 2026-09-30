public with sharing class MockPaymentAdapter
implements commercepayments.PaymentGatewayAdapter {

    public commercepayments.GatewayResponse processRequest(
        commercepayments.PaymentGatewayContext context) {

        commercepayments.RequestType requestType =
            context.getPaymentRequestType();

        commercepayments.PaymentGatewayRequest request =
            context.getPaymentRequest();

        System.debug('Processing Request Type : ' + requestType);

        switch on requestType {

            when Tokenize {

                return tokenize(
                    (commercepayments.PaymentMethodTokenizationRequest)request
                );
            }

            when Authorize {

                return authorize(
                    (commercepayments.AuthorizationRequest)request
                );
            }

            when Capture {

                return capture(
                    (commercepayments.CaptureRequest)request
                );
            }

            when Sale {

                return sale(
                    (commercepayments.SaleRequest)request
                );
            }

            when else {

                return new commercepayments.GatewayErrorResponse(
                    '400',
                    'Unsupported Request'
                );
            }
        }
    }


    // -------------------------------
    // TOKENIZE
    // -------------------------------

    private commercepayments.PaymentMethodTokenizationResponse tokenize(
        commercepayments.PaymentMethodTokenizationRequest req) {

        System.debug('Mock Tokenization Started');

        commercepayments.PaymentMethodTokenizationResponse res =
            new commercepayments.PaymentMethodTokenizationResponse();

        // Fake token for POC
        String mockToken =
            'MOCK-TOKEN-' + String.valueOf(DateTime.now().getTime());

        res.setGatewayToken(mockToken);

        res.setGatewayTokenDetails(
            'Mock Credit Card Token'
        );

        res.setGatewayResultCode('00');

        res.setGatewayResultCodeDescription(
            'Tokenization Successful'
        );

        res.setSalesforceResultCodeInfo(
            new commercepayments.SalesforceResultCodeInfo(
                commercepayments.SalesforceResultCode.SUCCESS
            )
        );

        System.debug('Generated Mock Token : ' + mockToken);

        return res;
    }


    // -------------------------------
    // AUTHORIZE
    // -------------------------------

    private commercepayments.AuthorizationResponse authorize(
        commercepayments.AuthorizationRequest req) {

        System.debug('Mock Authorization Started');

        commercepayments.AuthorizationResponse res =
            new commercepayments.AuthorizationResponse();

        res.setAmount(req.amount);

        res.setGatewayReferenceNumber(
            'AUTH-' + DateTime.now().getTime()
        );

        res.setGatewayResultCode('00');

        res.setGatewayResultCodeDescription(
            'Authorization Successful'
        );

        res.setSalesforceResultCodeInfo(
            new commercepayments.SalesforceResultCodeInfo(
                commercepayments.SalesforceResultCode.SUCCESS
            )
        );

        return res;
    }


    // -------------------------------
    // CAPTURE
    // -------------------------------

    private commercepayments.CaptureResponse capture(
        commercepayments.CaptureRequest req) {

        System.debug('Mock Capture Started');

        commercepayments.CaptureResponse res =
            new commercepayments.CaptureResponse();

        res.setAmount(req.amount);

        res.setGatewayReferenceNumber(
            'CAP-' + DateTime.now().getTime()
        );

        res.setGatewayResultCode('00');

        res.setGatewayResultCodeDescription(
            'Capture Successful'
        );

        res.setSalesforceResultCodeInfo(
            new commercepayments.SalesforceResultCodeInfo(
                commercepayments.SalesforceResultCode.SUCCESS
            )
        );

        return res;
    }


    // -------------------------------
    // SALE
    // -------------------------------

    private commercepayments.SaleResponse sale(
        commercepayments.SaleRequest req) {

        System.debug('Mock Sale Started');

        commercepayments.SaleResponse res =
            new commercepayments.SaleResponse();

        res.setAmount(req.amount);

        res.setGatewayReferenceNumber(
            'SALE-' + DateTime.now().getTime()
        );

        res.setGatewayResultCode('00');

        res.setGatewayResultCodeDescription(
            'Payment Approved'
        );

        res.setSalesforceResultCodeInfo(
            new commercepayments.SalesforceResultCodeInfo(
                commercepayments.SalesforceResultCode.SUCCESS
            )
        );

        return res;
    }
}