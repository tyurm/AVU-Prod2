pageextension 82003 "AVU Chart of Accounts" extends "Chart of Accounts"
{
    layout
    {
        addafter("Name")
        {
            field("AVU Name 2"; "AVU Name 2")
            {
                ApplicationArea = All;
            }
        }
    }
}