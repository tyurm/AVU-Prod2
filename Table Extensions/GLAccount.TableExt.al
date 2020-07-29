tableextension 82006 "AVU G/L Account" extends "G/L Account"
{
    fields
    {
        field(82000; "AVU Name 2"; Text[100])
        {
            Caption = 'Name 2';
            DataClassification = CustomerContent;
        }
    }
}