pageextension 82034 "AVU Currencies" extends Currencies
{
    layout
    {
        // Add changes to page layout here
        addafter(ExchangeRateAmt)
        {
            field(AddVATExchangeRateDate; AddVATExchangeRateDate)
            {
                ApplicationArea = Suite;
                Caption = 'Add. VAT Exchange Rate Date';
                Editable = false;
                Visible = AddVATLogicEnabled;
                ToolTip = 'Specifies the date of the exchange rate in the Exchange Rate field. You can update the rate by choosing the Update Exchange Rates button.';

                trigger OnDrillDown()
                begin
                    DrillDownCHFActionOnPage;
                end;
            }
            field(CHFExchangeRateAmt; AddVATExchangeRateAmt)
            {
                ApplicationArea = Suite;
                Caption = 'Add. VAT Exchange Rate';
                DecimalPlaces = 0 : 7;
                Editable = false;
                Visible = AddVATLogicEnabled;
                ToolTip = 'Specifies the currency exchange rate. You can update the rate by choosing the Update Exchange Rates button.';

                trigger OnDrillDown()
                begin
                    DrillDownCHFActionOnPage;
                end;
            }
        }
    }

    actions
    {

        addafter("Exch. &Rates")
        {
            action("Add. VAT Exch. Rates")
            {
                ApplicationArea = All;
                Caption = 'Add. VAT Exch. Rates';
                Enabled = AddVATLogicEnabled;
                Image = CurrencyExchangeRates;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "AVU Add. VAT Exchange Rates";
                RunPageLink = "Currency Code" = FIELD(Code);
            }
        }
    }
    local procedure DrillDownCHFActionOnPage()
    var
        CHFExchRate: Record "AVU Add. VAT Exchange Rate";
    begin
        CHFExchRate.SetRange("Currency Code", Code);
        PAGE.RunModal(0, CHFExchRate);
        CurrPage.Update(false);
    end;

    trigger OnOpenPage()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.get;
        AddVATLogicEnabled := GLSetup.AdditionalVATLogicEnabled;
    end;

    trigger OnAfterGetRecord()
    var
        CHFExchangeRate: Record "AVU Add. VAT Exchange Rate";
    begin
        if AddVATLogicEnabled then
            CHFExchangeRate.GetLastestExchangeRate(Code, AddVATExchangeRateDate, AddVATExchangeRateAmt);

    end;

    var
        AddVATExchangeRateAmt: Decimal;
        AddVATExchangeRateDate: Date;
        AddVATLogicEnabled: boolean;
}