pageextension 82001 "AVU Contact List" extends "Contact List"
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