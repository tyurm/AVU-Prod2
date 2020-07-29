page 82004 "AVU Alcohol Percents"
{

    PageType = List;
    SourceTable = "AVU Alcohol Percent";
    Caption = 'Alcohol Percents';
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field(Code; Code)
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
