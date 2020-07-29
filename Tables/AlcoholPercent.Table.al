table 82003 "AVU Alcohol Percent"
{
    Caption = 'Alcohol Percent';
    LookupPageId = "AVU Alcohol Percents";
    DrillDownPageId = "AVU Alcohol Percents";
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
