package;
import haxe.io.Input;
import haxe.io.Output;
import sys.io.File;

/**
 * ...
 * @author Vincent Blanchet
 */

typedef Location = {
	var file:String;
	var lines:Array<Int>;
}
 
class TradBlock
{
	public var references:Array<Location>;
	public var msgid:String;
	public var msgstr:String;
	public var translatorComments:Array<String>;
	public var extractedComments:Array<String>;
	public var flags:Array<String>;
	
	
	var basePath:String;
	
	public function new(basePath:String) 
	{
		references = [];
		translatorComments = [];
		extractedComments = [];
		flags = [];
		
		msgid = "";
		msgstr = "";
		
		this.basePath = basePath;
	}
	
	public function run(overrideFile:Bool=false):Void
	{
		var sf:haxe.io.Input;
		var line:String = "";
		
		if (msgid == "" || msgstr == "")
		{
			trace(this);
			return;
		}
		
		
		
		for (des in references)
		{
			var b = new StringBuf();
			//var datas = des.split(":");
			//var path = basePath + "/"+ datas[0];
			//var lineNum:Int = Std.parseInt(datas[1]);
			sf = File.read(basePath+"/"+des.file);
			var currentLine = 0;
			for (i in 0...des.lines.length)
			{
				var lineNum = des.lines[i];
				
				//progress to next matching
				while (currentLine < lineNum)
				{
					line = sf.readLine();
					currentLine++;
					if(currentLine < lineNum)
						b.add(line+"\n");
				}
				//remove '"/n"'
				var r = ~/"\/n"/g;
				var cleanMsgid = r.replace(msgid, "");
				var cleanMsgstr = r.replace(msgstr, "");
				
				if (cleanMsgid != msgid)
					trace("msgid: "+cleanMsgid + " != " + msgid);
				if (cleanMsgstr != msgstr)
					trace("msgstr: "+cleanMsgstr + " != " + msgstr);
				
				var changedLine = "";
				//replace traduction
				if (line.indexOf(cleanMsgid) != -1)
				{
					changedLine = StringTools.replace(line, cleanMsgid, cleanMsgstr);
				}else{
					trace("________________________");
					
					trace(this);
					trace("line :" + line);
					trace("msgid: " + cleanMsgid + " != " + msgid);
					trace("________________________");
				}
				
				
				b.add(changedLine+"\n");	
			}
			
			//every instance from the file are replaced copy remaining lines in buffer
			try {
				while(true){
					b.add(sf.readLine() + "\n");
				}
			}catch (e:Dynamic) {
					//trace(e);
			}
			sf.close();
			
			//save buffer to a new file
			var temp = des.file.split("/").pop();
			var dest = File.write(basePath+"/"+des.file+((overrideFile)?"":".trad"),false);
			dest.writeString(b.toString());
			dest.close();
			
				//trace(line);
			
			
		}
	}
	
	public function addReference(location:String)
	{
		
		var data = location.split(":");
		var existing = references.filter(function(l) { return l.file == data[0]; } );
		
		if (existing.length == 0)
		{
			references.push( { file:data[0], lines:[Std.parseInt(data[1])] } );
		}else {
			//trace("existing:" + existing);
			existing[0].lines.push(Std.parseInt(data[1]));
		}
		
	}
	
	public function toReverseString():String
	{
		var res = "";
		
		res += propertiesToString();
		
		res += 'msgid "' + msgstr + '"\n';
		res += 'msgstr "' + msgid + '"\n';
		
		return res;
	}
	
	public function toString():String
	{
		var res = "";
		
		res += propertiesToString();
		
		res += 'msgid "' + msgid + '"\n';
		res += 'msgstr "' + msgstr + '"\n';
		
		return res;
	}
	
	function propertiesToString():String
	{
		var res = "";
		
		for (c in translatorComments)
		{
			res += "# " + c + "\n";
		}
		
		for (ec in extractedComments)
		{
			res += "#. " + ec + "\n";
		}
		
		for (des in references)
		{
			for (i in 0...des.lines.length)
			{
				res += "#: " + des.file +":"+des.lines[i]+ "\n";
			}
		}
		
		
		for (f in flags)
		{
			res += "#, " + f + "\n";
		}
		
		return res;
	}
}