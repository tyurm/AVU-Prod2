pageextension 82038 "AVU VAT Statement" extends "VAT statement"
{
    actions
    {
        modify("P&review")
        {
            Visible = NOT AddVATLogicEnabled;
        }

        addafter("P&review")
        {
            action("VAT Preview")
            {
                Caption = 'VAT Preview';
                Visible = AddVATLogicEnabled;
                ApplicationArea = VAT;
                Image = View;
                Promoted = true;
                PromotedCategory = Process;
                RunObject = Page "AVU VAT Statement Preview";
                RunPageLink = "Statement Template Name" = FIELD("Statement Template Name"),
                                  Name = FIELD("Statement Name");
                ToolTip = 'Preview the VAT statement report.';
            }
        }
    }

    trigger OnOpenPage()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if GLSetup.get then
            AddVATLogicEnabled := GLSetup.AdditionalVATLogicEnabled;
    end;

    var
        AddVATLogicEnabled: Boolean;
}