codeunit 82000 "AVU Events"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Table, Database::"VAT Entry", 'OnBeforeInsertEvent', '', false, false)]
    local procedure UpdateAVUAdditionalVATEntryFields(var Rec: Record "VAT Entry"; RunTrigger: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
        AddVATExchRate: Record "AVU Add. VAT Exchange Rate";
    begin
        if (RunTrigger = false) or rec.IsTemporary then
            exit;

        GLSetup.Get;
        if GLSetup."AVU VAT Reporting Currency" = '' then
            exit;

        if Rec."Currency Code" <> '' then begin
            Rec."AVU Add. VAT Base Amount" := AddVATExchRate.ExchangeAmtFCYToACY(Rec."Posting Date", Rec."Currency Code", Rec."Base (FCY)");
            Rec."AVU Add. VAT Amount" := AddVATExchRate.ExchangeAmtFCYToACY(Rec."Posting Date", Rec."Currency Code", Rec."Amount (FCY)");
        end else begin
            Rec."AVU Add. VAT Base Amount" := AddVATExchRate.ExchangeAmtFCYToACY(Rec."Posting Date", GLSetup."AVU LCY Curr. for VAT Rep.", Rec."Base");
            Rec."AVU Add. VAT Amount" := AddVATExchRate.ExchangeAmtFCYToACY(Rec."Posting Date", GLSetup."AVU LCY Curr. for VAT Rep.", Rec."Amount");
        end;
    end;
}