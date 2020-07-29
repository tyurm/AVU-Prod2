tableextension 82010 "AVU General Ledger Setup" extends "General Ledger Setup"
{
    fields
    {
        field(82000; "AVU VAT Reporting Currency"; Code[10])
        {
            Caption = 'VAT Reporting Currency';
            DataClassification = CustomerContent;
            TableRelation = Currency;
        }
        field(82001; "AVU LCY Curr. for VAT Rep."; Code[10])
        {
            Caption = 'LCY Currency for VAT Reporting';
            DataClassification = CustomerContent;
            TableRelation = Currency;
        }
    }
    procedure AdditionalVATLogicEnabled(): Boolean
    begin
        EXIT("AVU VAT Reporting Currency" <> '');
    end;

}