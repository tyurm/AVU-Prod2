table 82000 "AVU Vintage"
{
    Caption = 'Vintage';
    LookupPageId = "AVU Vintage";
    DrillDownPageId = "AVU Vintage";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[10])
        {
            Caption = 'Code';
            DataClassification = CustomerContent;
        }
        field(2; Description; Text[50])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
    }
    keys
    {
        key(PK; Code)
        {
            Clustered = true;
        }
    }

}
