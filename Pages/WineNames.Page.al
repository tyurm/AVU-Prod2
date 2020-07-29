page 82007 "AVU Wine Names"
{
    PageType = List;
    SourceTable = "AVU Wine Name";
    Caption = 'Wine Names';
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Name; Name)
                {
                    ApplicationArea = All;
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

}
