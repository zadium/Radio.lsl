/**
    @name: Radio
    @description:

    @author: Zai Dium
    @version: 1.0
    @updated: "2022-10-21 15:57:13"
    @revision: 426
    @localfile: ?defaultpath\Radio\?@name.lsl
    @license: ?

    @ref:

    @notice:

    Add this script and readme to your object
    Add notecards for each genre name it with .list at the end, example "Country.list"
    edit gene notecard add a list of url of streams, you can optional add name for each one before =, or just keep it as url
    example:

    My Name=http://blabla.com:8010/mystation1
    http://blabla.com:8010/mystation2
*/

//* settings

//* variables
string full_version = "Radio 1.2";

key notecardQueryId;
integer notecardLine;
integer notecardIndex = 0;
string notecardName = "";

string radioStation = "";
string radioGenre = "";

list radioGenres = [];
list radioNames = [];
list radioStations = [];

integer TAB_Home = 0;
integer TAB_Stations = 1;
integer TAB_Genre = 2;

integer menuTab = 0;
key dialogFor = NULL_KEY;

list getMenuList(key id) {
    list l;
    if (menuTab == TAB_Home)
    {
        l += ["Stations", "Genre"];

        if (id == llGetOwner())
        {
        }
    }
    else if (menuTab == TAB_Genre)
    {
        l += radioGenres;
    }
    else if (menuTab == TAB_Stations)
    {
        l += radioNames;
    }
    return l;
}

list cmd_menu = [ "<--", "---", "-->" ]; //* general navigation

list getMenu(key id)
{
    list commands = getMenuList(id);
    integer length = llGetListLength(commands);
    if (length >= 9)
    {
        integer x = cur_page * 9;
        return cmd_menu + llList2List(commands, x , x + 8);
    }
    else {
        return cmd_menu + commands;
    }
}

integer dialog_channel;
integer cur_page; //* current menu page
integer dialog_listen_id;

showDialog(key id)
{
    dialog_channel = -1 - (integer)("0x" + llGetSubString( (string) llGetKey(), -7, -1) );
    llListenRemove(dialog_listen_id);
    string title;
    if (menuTab == TAB_Home)
        title = "Select command";
    else if (menuTab == TAB_Genre)
        title = "Select Genre";
    else if (menuTab == TAB_Stations)
        title = "Select Stations";
    llDialog(id, "Page: " + (string)(cur_page+1) + " " + title, getMenu(id), dialog_channel);
    dialog_listen_id = llListen(dialog_channel, "", id, "");
}

updateText()
{
    string s = "Genre: " + radioGenre;
    s += "\nStation: " + radioStation;
    llSetText(s, <1.0, 1.0, 1.0>, 1.0);
}

readNotecard(string name)
{
    if (name != "")
    {
        notecardName = name + ".list";
        if (llGetInventoryKey(notecardName) != NULL_KEY)
        {
	        radioGenre = name;
            radioNames = [];
            radioStations = [];
            notecardLine = 0;
            notecardIndex = 0;
            llOwnerSay("Reading " + notecardName + "...");
            notecardQueryId = llGetNotecardLine(notecardName, notecardLine);
        }
    }
}

readGenres()
{
	radioGenres = [];
    integer count = llGetInventoryNumber(INVENTORY_NOTECARD);
    integer index = 0;
    while (index < count) {
    	string name = llGetInventoryName(INVENTORY_NOTECARD, index);
	    if (llToLower(llGetSubString(name, -5, -1)) == ".list")
        {
	        name = llGetSubString(name, 0, -6);
    	    radioGenres += name;
        }
        index++;
    }
}

reset(){
    readGenres();
    if (radioGenre == "")
	    radioGenre = llList2String(radioGenres, 0);
    readNotecard(radioGenre);
}

setRadioStation(string station)
{
    radioStation = station;
    llShout(0, "Radio stream now: " + station);
    llSetParcelMusicURL(station);
}

default
{
    state_entry()
    {
        if (llGetOwner() == llGetCreator())
            llSetObjectName(full_version);
        reset();
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY) {
            reset();
        }
    }

    touch_start(integer num_detected)
    {
        key id = llDetectedKey(0);
        menuTab = TAB_Home;
        showDialog(id);
    }

    listen(integer channel, string name, key id, string message)
    {
        if (channel == dialog_channel)
        {
            llListenRemove(dialog_listen_id);
            if (message == "---")
            {
                menuTab = TAB_Home;
                cur_page = 0;
                showDialog(id);
            }
            else if (message == "<--")
            {
                if (cur_page > 0)
                    cur_page--;
                showDialog(id);
            }
            else if (message == "-->")
            {
                integer max_limit = llGetListLength(getMenuList(id)) / 9;
                if ((max_limit > 0) && (cur_page < max_limit))
                    cur_page++;
                showDialog(id);
            }
            //* Commands
            else
            {
                if (menuTab == TAB_Home)
                {
                    if (message == "Genre")
                    {
                        menuTab = TAB_Genre;
                        showDialog(id);
                    }
                    else if (message == "Stations")
                    {
                        menuTab = TAB_Stations;
                        showDialog(id);
                    }
                }
                else if (menuTab == TAB_Stations)
                {
                    integer index = llListFindList(radioNames, [message]);
                    if (index>=0)
                    {
                        string station = llList2String(radioStations, index);
                        setRadioStation(station);
                    }
                    menuTab = TAB_Home;
                }
                else if (menuTab == TAB_Genre)
                {
                    integer index = llListFindList(radioGenres, [message]);
                    if (index>=0)
                    {
                        readNotecard(message);
                    }
                    menuTab = TAB_Stations;
                    dialogFor = id;
                    //showDialog(id);
                }
            }
        }
    }

    dataserver( key queryid, string data )
    {
        if (queryid == notecardQueryId)
        {
            if (data == EOF) //Reached end of notecard (End Of File).
            {
                notecardQueryId = NULL_KEY;
                if (dialogFor != NULL_KEY)
                {
                    menuTab = TAB_Stations;
                    showDialog(dialogFor);
                    dialogFor = NULL_KEY;
                }
                //llOwnerSay("Read radio station count: " + (string)llGetListLength(radioStations));
            }
            else
            {
                if ((llToLower(llGetSubString(data, 0, 0)) != "#") && (llToLower(llGetSubString(data, 0, 0)) != ";"))
                {
                    //llOwnerSay("reading "+data);

                    integer p = llSubStringIndex(data, "=");
                    string name = "";
                    if (p>=0) {
                        name = llStringTrim(llGetSubString(data, 0, p - 1), STRING_TRIM);
                        data = llStringTrim(llGetSubString(data, p + 1, -1), STRING_TRIM);
                    }

                    if (name == "")
                    {
                        //* guess the name
                        list values = llParseString2List(data,["/"], []);
                        if (llList2String(values, 0) == "http:")
                        	values = llDeleteSubList(values, 0, 0);
                        else if (llList2String(values, 0) == "https:")
                        	values = llDeleteSubList(values, 0, 0);

                        name = llList2String(values, llGetListLength(values) - 1);
                        if (name == "")
	                        name = llList2String(values, 0);

                        if (name == "")
                        {
                            name = (string)notecardIndex;
                            notecardIndex++;
                        }
                    }

                    radioNames += name;
                    radioStations += data;
                }

                ++notecardLine;
                notecardQueryId = llGetNotecardLine(notecardName, notecardLine); //Query the dataserver for the next notecard line.
            }
        }
    }
}
