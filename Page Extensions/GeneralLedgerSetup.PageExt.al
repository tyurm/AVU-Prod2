pageextension 82037 "AVU General Ledger Setup" extends "General Ledger Setup"
{
    layout
    {
        addafter("Local Currency Description")
        {
            field("AVU VAT Reporting Currency"; "AVU VAT Reporting Currency")
            {
                Caption = 'VAT Reporting Currency';
                ToolTip = 'Specifies the currency that will be used as VAT reporting currency.';
                ApplicationArea = All;
                trigger OnValidate()
                var
                    AddVATExchRate: Record "AVU Add. VAT Exchange Rate";
                    AddVATExchRateNotEmpty: Label 'Additional VAT Exchange Rate table should be empty!';
                begin
                    if "AVU VAT Reporting Currency" = '' then begin
                        if not AddVATExchRate.IsEmpty then
                            error(AddVATExchRateNotEmpty);

                        "AVU LCY Curr. for VAT Rep." := '';
                    end;
                    CurrPage.update();
                end;


            }
            field("AVU LCY Curr. for VAT Rep."; "AVU LCY Curr. for VAT Rep.")
            {
                Caption = 'LCY Currency for VAT Reporting';
                ToolTip = 'Specifies the currency that will be used as LCY currency for VAT reporting.';
                Enabled = AddVATLogicEnabled;
                ApplicationArea = All;
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        AddVATLogicEnabled := AdditionalVATLogicEnabled;
    end;

    var
        AddVATLogicEnabled: boolean;
}