tableextension 82009 "AVU Posted Payment Recon. Line" extends "Posted Payment Recon. Line"
{
    fields
    {
        field(82000; "AVU Description 1"; Text[250])
        {
            Caption = 'AVU Description 1';
            DataClassification = CustomerContent;
        }
        field(82001; "AVU Description 2"; Text[250])
        {
            Caption = 'AVU Description 2';
            DataClassification = CustomerContent;
        }
        field(82002; "AVU Description 3"; Text[250])
        {
            Caption = 'AVU Description 3';
            DataClassification = CustomerContent;
        }
    }


}