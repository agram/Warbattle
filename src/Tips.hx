import Common;

class Tips extends h2d.ScaleGrid
{
	public var tempsO:Float;
	public var tempsC:Float;
	static var TIME = 10;
	var game:Game;
	public var texte:h2d.Text;
	
	public var time:Float;
	
	public function new() 
	{
		game = Game.inst;
		super(game.gfx.message.main[0], 8, 8);
		visible = false;
		colorKey = 0xFFFFFFFF;
		width = 400;
		height = 60;
		tempsO = -1;
		tempsC = -1;
		scaleX = 0;
		scaleY = 0;
		
		var font = Res.Minecraftia.build(8, { antiAliasing : false } );
		texte = new h2d.Text(font);
		texte.x = 8;
		texte.y = 8;
		texte.color = new h3d.Vector();
		addChild(texte);
		
		time = 0;
	}
	
	public function update(dt:Float, x, y) {
		this.x = x;
		this.y = y;
		
		if (time > 0) {
			if (time == 1) open();
			time--;
		}
		
		if (tempsC > 0) {
			tempsC--;
			scaleX = tempsC / TIME;
			scaleY = tempsC / TIME;
		}			
		if(tempsC == 0) {
			//visible = false;
			//scaleX = 0;
			//scaleY = 0;
			return true;
		}
		if (tempsO > 0) {
			tempsO--;
			scaleX = (TIME-tempsO) / TIME;
			scaleY = (TIME-tempsO) / TIME;
		}			
		if(tempsO == 0) {
			tempsO = -1;
		}
		return false;
	}
	
	public function open(t:String = null) {
		visible = true;
		tempsO = TIME;
		tempsC = -1;
		if (t != null) texte.text = t;
	}
	
	public function close() {
			tempsC = TIME;
			tempsO = -1;
	}	
	
}