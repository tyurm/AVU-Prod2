pageextension 82033 "AVU Sales Credit Memo" extends "Sales Credit Memo"
{
    layout
    {
        addafter("External Document No.")
        {
            field("Posting No."; "Posting No.")
            {
                ApplicationArea = All;
                Importance = Additional;
                Visible = false;
            }
            field("Return Receipt No."; "Return Receipt No.")
            {
                ApplicationArea = All;
                Importance = Additional;
                Visible = false;
            }
        }
    }

    var
        myInt: Integer;
}