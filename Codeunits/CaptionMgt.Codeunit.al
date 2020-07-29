codeunit 82004 "AVU Caption Mgt."
{
    trigger OnRun()
    begin

    end;

    procedure GetVATCaptionClass(FielCpt: text): Text[80]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        AddVATCurrCode: code[10];
    begin
        if GeneralLedgerSetup.get then
            AddVATCurrCode := GeneralLedgerSetup."AVU VAT Reporting Currency";
        if AddVATCurrCode = '' then
            exit;
        EXIT('3,' + FielCpt + STRSUBSTNO(' (%1)', AddVATCurrCode))
    end;

}