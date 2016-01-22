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
	public var locations:Array<Location>;
	public var msgid:String;
	public var msgstr:String;
	
	
	
	var basePath:String;
	
	public function new(basePath:String) 
	{
		locations = [];
		
		this.basePath = basePath;
	}
	
	public function run(overrideFile:Bool=false):Void
	{
		var sf:haxe.io.Input;
		var line:String = "";
		for (des in locations)
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
				//replace traduction
				line = StringTools.replace(line, msgid, msgstr);
				b.add(line+"\n");	
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
	
	public function addLocation(location:String)
	{
		
		var data = location.split(":");
		var existing = locations.filter(function(l) { return l.file == data[0]; } );
		
		if (existing.length == 0)
		{
			locations.push( { file:data[0], lines:[Std.parseInt(data[1])] } );
		}else {
			//trace("existing:" + existing);
			existing[0].lines.push(Std.parseInt(data[1]));
		}
		
	}
	
	public function toReverseString():String
	{
		var res = "";
		for (des in locations)
		{
			for (i in 0...des.lines.length)
			{
				res += "#: " + des.file +":"+des.lines[i]+ "\n";
			}
		}
		res += 'msgid "' + msgstr + '"\n';
		res += 'msgstr "' + msgid + '"\n';
		
		return res;
	}
}