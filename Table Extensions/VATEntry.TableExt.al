tableextension 82011 "AVU VAT Entry" extends "VAT Entry"
{
    fields
    {

        field(82000; "AVU Add. VAT Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = AVUGetVATCurrencyCode;
            Caption = 'Add. Amount';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(82001; "AVU Add. VAT Base Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = AVUGetVATCurrencyCode;
            Caption = 'Add. Base';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
    local procedure AVUGetVATCurrencyCode(): code[10]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if GLSetup.get then
            exit(GLSetup."AVU VAT Reporting Currency");

    end;
}