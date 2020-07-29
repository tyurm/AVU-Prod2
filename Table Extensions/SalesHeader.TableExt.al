tableextension 82002 "AVU Sales Header" extends "Sales Header"
{
    fields
    {
        field(82000; "AVU Assignee Code"; Code[20])
        {
            Caption = 'Assignee Code';
            TableRelation = "Salesperson/Purchaser";
            DataClassification = CustomerContent;
        }
    }
}