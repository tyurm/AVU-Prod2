pageextension 82031 "AVU Sales Order Subform" extends "Sales Order Subform"
{
    layout
    {
        modify("Reserved Quantity")
        {
            Visible = false;
        }
        modify("Tax Area Code")
        {
            Visible = false;
        }
        modify("Tax Group Code")
        {
            Visible = false;
        }
        modify("Shortcut Dimension 1 Code")
        {
            Visible = false;
        }
        modify("Shortcut Dimension 2 Code")
        {
            Visible = false;
        }
        modify(ShortcutDimCode3)
        {
            Visible = false;
        }
        addlast(Control1)
        {
            field("AVU Vat %"; "Vat %")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("AVU Gen. Bus. Posting Group"; "Gen. Bus. Posting Group")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("AVU Gen. Prod. Posting Group"; "Gen. Prod. Posting Group")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("AVU VAT Bus. Posting Group"; "VAT Bus. Posting Group")
            {
                ApplicationArea = All;
                Visible = false;
            }
            field("AVU VAT Identifier"; "VAT Identifier")
            {
                ApplicationArea = All;
                Visible = false;
            }
        }
        addafter("AVU VAT Identifier")
        {
            field("AVU VATDifference"; VATDifference)
            {
                ApplicationArea = All;
                Caption = 'VAT Difference';
                trigger OnValidate()
                begin
                    Validate("VAT Difference", VATDifference);
                    UpdateForm(true);
                    //VATDifference := "VAT Difference";
                end;
            }
        }
    }
    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        VATDifference := "VAT Difference";
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        VATDifference := 0;
    end;

    var
        VATDifference: Decimal;
}
