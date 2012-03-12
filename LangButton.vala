// For some strange reaon, if i subclass PickerButton,
// it is displayed with invalid 'flat' style. So, i
// use PickerButton directly.
public class LangButton
{
    public static Hildon.PickerButton create()
    {
        var btn = new Hildon.PickerButton(
            Hildon.SizeType.HALFSCREEN_WIDTH | Hildon.SizeType.FINGER_HEIGHT,
            Hildon.ButtonArrangement.VERTICAL
        );
        btn.title = "Language";

        var selector = new Hildon.TouchSelector.text();

        var active = 0;
        var index = 0;
        foreach (var lang in Languages.instance.langs())
        {
            selector.append_text(lang.engname + " (" + lang.selfname + ")");

            if (lang == Languages.instance.current)
                active = index;

            index++;
        }

        selector.set_active(0, active);

        btn.set_selector(selector);

        return btn;
    }
}
