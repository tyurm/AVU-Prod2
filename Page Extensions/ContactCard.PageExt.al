pageextension 82002 "AVU Contact Card" extends "Contact Card"
{
    layout
    {
        addafter("Name")
        {
            field("AVU Title"; "AVU Title")
            {
                ApplicationArea = All;
            }
        }
    }
}