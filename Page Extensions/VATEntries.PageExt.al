pageextension 82036 "AVU VAT Entries" extends "VAT Entries"
{
    layout
    {
        addafter(Amount)
        {
            field("AVU Add. VAT Base Amount"; "AVU Add. VAT Base Amount")
            {
                ApplicationArea = All;
                CaptionClass = AVUCaptionMgt.GetVATCaptionClass(FieldCaption("AVU Add. VAT Base Amount"));
                ToolTip = 'Specifies the amount that the VAT amount is calculated from in Additional VAT Currency.';
                Visible = AddVATLogicEnabled;
            }
            field("AVU Add. VAT Amount"; "AVU Add. VAT Amount")
            {
                ApplicationArea = All;
                CaptionClass = AVUCaptionMgt.GetVATCaptionClass(FieldCaption("AVU Add. VAT Amount"));
                ToolTip = 'Specifies the amount of the VAT entry in Additional VAT Currency';
                Visible = AddVATLogicEnabled;
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

        AVUCaptionMgt: Codeunit "AVU Caption Mgt.";
        AddVATLogicEnabled: Boolean;
}