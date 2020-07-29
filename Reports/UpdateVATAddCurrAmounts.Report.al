report 82007 "Update Add. Currency VAT Amts"
{
    Caption = 'Update Add. Currency VAT Amounts';
    UsageCategory = Tasks;
    ApplicationArea = All;
    ProcessingOnly = true;
    dataset
    {
        dataitem("VAT Entry"; "VAT Entry")
        {
            RequestFilterFields = "Document Type", "Document No.", "Document Date";
            trigger OnPreDataItem()
            begin
                SetRange("AVU Add. VAT Base Amount", 0);
                SetRange("AVU Add. VAT Amount", 0);
            end;


            trigger OnAfterGetRecord()
            var
                GLSetup: Record "General Ledger Setup";
                AddVATExchRate: record "AVU Add. VAT Exchange Rate";
            begin
                GLSetup.Get;
                if GLSetup."AVU VAT Reporting Currency" = '' then
                    exit;
                if "Currency Code" <> '' then begin
                    "AVU Add. VAT Base Amount" := AddVATExchRate.ExchangeAmtFCYToACY("Posting Date", "Currency Code", "Base (FCY)");
                    "AVU Add. VAT Amount" := AddVATExchRate.ExchangeAmtFCYToACY("Posting Date", "Currency Code", "Amount (FCY)");
                end else begin
                    "AVU Add. VAT Base Amount" := AddVATExchRate.ExchangeAmtFCYToACY("Posting Date", GLSetup."AVU LCY Curr. for VAT Rep.", "Base");
                    "AVU Add. VAT Amount" := AddVATExchRate.ExchangeAmtFCYToACY("Posting Date", GLSetup."AVU LCY Curr. for VAT Rep.", "Amount");
                end;
                modify;
            end;
        }
    }

    requestpage
    {
        layout
        {
        }

    }
}