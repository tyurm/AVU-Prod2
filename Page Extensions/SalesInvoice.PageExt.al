pageextension 82029 "AVU Sales Invoice" extends "Sales Invoice"
{
    layout
    {
        addafter("External Document No.")
        {
            field("Posting No."; "Posting No.")
            {
                ApplicationArea = All;
                Importance = Additional;
            }
        }
    }
    actions
    {
    }
}
