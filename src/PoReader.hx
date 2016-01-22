package;
import haxe.ds.StringMap;
import haxe.io.Eof;
import haxe.io.Input;
import sys.io.File;

/**
 * Parse po file and treat each traduction block
 * @author Vincent Blanchet
 */
class PoReader
{
	var po:Input;
	var line:String;
	var fc:String;//first char of line
	var basePath:String;
	var poDir:String;
	var msgstrMap:StringMap<Int>;
	var cpt:Int;

	public var res:String;
	public var duplicated:String;
	
	public function new(path:String,overrideFile:Bool) 
	{
		var tmp = path.split("/");
		tmp.pop();
		poDir = tmp.join("/") + "/";
		msgstrMap = new StringMap<Int>();
		
		res = "";
		try{
			po = File.read(path);	
		}catch (e:Dynamic) {
			throw("file " + path + " not found");
		}
		parseHeader();
		parseTrad(overrideFile);
		po.close();
	}
	
	function parseHeader()
	{
		do{
			line = po.readLine();
			var basePathEx = ~/^"X-Poedit-Basepath: (.*)\\n"/;
			if (basePathEx.match(line))
			{
				basePath = poDir+basePathEx.matched(1);
				trace("basePath:" + basePath);
			}
			fc = line.charAt(0);
			res += line+"\n";
			//trace(line);
		}while (fc == "m" || fc == "\"");
		trace("header parsed");
	}
	
	function parseTrad(overrideFile:Bool):Void
	{
		var status = "normal";
		var tb = new TradBlock(basePath);
		cpt = 0;
		do{
			var msgidExp = ~/^msgid "(.*)"/i;//find msgid "something"
			var msgstrExp = ~/^msgstr "(.*)"/i;//find msgstr "something"
			var contentExp = ~/^"(.*)"/i;//find "something"
			try{
			line = po.readLine();
			}catch (e:Dynamic) {
				if (Std.string(e) == "Eof")
				{
					trace("end of file");
				}
				break;
			}
			
			
			//check content
			if (line.substr(0, 2) == "#~") { //comment
				res += line+"\n";
			}else if (line.substr(0, 2) == "#:")//location
			{
				//trace(line);
				tb.addLocation(line.substr(3));
			}else if ( msgidExp.match(line))//message id
			{
				tb.msgid = msgidExp.matched(1);
				
				if (tb.msgid == "")//start a multiline id
				{
					status = "msgid";
				}
			}else if ( msgstrExp.match(line))//message translation
			{
				tb.msgstr = msgstrExp.matched(1);
				
				if (tb.msgstr == "") //start a multiline str
				{
					status = "msgstr";
					continue;
				}
				
				tb.run(overrideFile);
				cpt++;
				if (msgstrMap.exists(tb.msgstr))
				{
					duplicated += tb.toReverseString() + "\n";
					msgstrMap.set(tb.msgstr,cast(msgstrMap.get(tb.msgstr),Int)+1);
				}else{
					res += tb.toReverseString() + "\n";
					msgstrMap.set(tb.msgstr,1);
				}
				tb = new TradBlock(basePath);
				
			}if (contentExp.match(line)) {//content for id or str
				
				if (status == "msgid")
				{
					tb.msgid += contentExp.matched(1);
					
				}else if (status == "msgstr"){
					tb.msgstr += contentExp.matched(1);
				}
			
			}else {
				if (status != "normal")//back to normal treat current pending block and start a new one
				{
					tb.run(overrideFile);
					cpt++;
					try{
					if (msgstrMap.exists(tb.msgstr))
					{
						duplicated += tb.toReverseString() + "\n";
						msgstrMap.set(tb.msgstr,cast(msgstrMap.get(tb.msgstr),Int)+1);
					}else{
						res += tb.toReverseString() + "\n";
						msgstrMap.set(tb.msgstr,1);
					}
					}catch (e:Dynamic) {
							throw "tb.msgstr:" + tb.msgstr + " " + e;
					}
					tb = new TradBlock(basePath);
					status == "normal";
				}
				res += line+"\n";
			}
		}while (line != null);
			
	}
	
	public function report():String
	{
		var rep = "treated : " + cpt + "\n";
		rep += "duplicated :\n";
		for (s in msgstrMap.keys())
		{
			var occurence = msgstrMap.get(s);
			if (occurence > 1)
			{
				rep += s +" : " + occurence+"\n";
			}
		}
		return rep;
	}
	
	
}