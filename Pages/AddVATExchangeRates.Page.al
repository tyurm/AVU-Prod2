page 82050 "AVU Add. VAT Exchange Rates"
{
    Caption = 'Add. VAT Exchange Rates';
    DataCaptionFields = "Currency Code";
    PageType = List;
    SourceTable = "AVU Add. VAT Exchange Rate";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date on which the exchange rate on this line comes into effect.';
                }
                field("Currency Code"; "Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the foreign currency on this line.';
                }
                field("Exchange Rate Amount"; "Exchange Rate Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amounts that are used to calculate exchange rates for the foreign currency on this line.';
                }
                field("Relational Exch. Rate Amount"; "Relational Exch. Rate Amount")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amounts that are used to calculate exchange rates for the foreign currency on this line.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        AddVATExchRate: Record "AVU Add. VAT Exchange Rate";
    begin
        AddVATExchRate := xRec;
        if not BelowxRec then begin
            AddVATExchRate.CopyFilters(Rec);
            if AddVATExchRate.Next(-1) <> 0 then
                TransferFields(AddVATExchRate, false)
        end else
            TransferFields(AddVATExchRate, false)
    end;
}

