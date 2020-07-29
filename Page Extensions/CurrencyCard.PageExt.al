pageextension 82035 "AVU Currency Card" extends "Currency Card"
{
    layout
    {
        // Add changes to page layout here
    }

    actions
    {
        // Add changes to page actions here
        addafter("Exch. &Rates")
        {
            action("Add. VAT Exch. Rates")
            {
                ApplicationArea = All;
                Caption = 'Add. VAT Exch. Rates';
                Enabled = AddVATLogicEnabled;
                Image = CurrencyExchangeRates;
                Promoted = true;
                PromotedCategory = Category4;
                RunObject = Page "AVU Add. VAT Exchange Rates";
                RunPageLink = "Currency Code" = FIELD(Code);
            }
        }
    }

    trigger OnOpenPage()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.get;
        AddVATLogicEnabled := GLSetup.AdditionalVATLogicEnabled;
    end;

    var
        AddVATLogicEnabled: boolean;
}