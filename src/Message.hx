import Common;

class Message extends h2d.ScaleGrid
{
	public var texte:h2d.Text;
	public var i:h2d.Interactive;
	var game:Game;

	public function new() 
	{
		game = Game.inst;
		super(game.gfx.message.main[0], 8, 8);
		visible = true;
		colorKey = 0xFFFFFFFF;
		width = Const.BASE_WIDTH - 400;
		height = 30;
		
		x = 200;
		y = Const.BASE_HEIGHT / 2 - 24;
		
		var font = Res.Minecraftia.build(8, { antiAliasing : false } );
		texte = new h2d.Text(font);
		texte.color = new h3d.Vector();
		texte.x = 8;
		texte.y = 8;
		this.addChild(texte);

		i = new h2d.Interactive(Const.BASE_WIDTH, Const.BASE_HEIGHT, this);
		i.x = -50;
		i.y = -Const.BASE_HEIGHT / 2 - 24;
		i.visible = false;
	}
	
}

class StatsTroup extends h2d.ScaleGrid
{
	public var texte:h2d.Text;
	public var i:h2d.Interactive;
	var game:Game;
	public var troupId:Int;
	
	public function new(troupId) 
	{
		game = Game.inst;
		super(game.gfx.message.statsTroup[0], 8, 8);
		this.troupId = troupId;
		visible = true;
		colorKey = 0xFFFFFFFF;
		width = 50;
		height = 50;
		
		x = 0;
		y = 0;
		
		var font = Res.Minecraftia.build(3, { antiAliasing : false } );
		texte = new h2d.Text(font);
		texte.color = new h3d.Vector();		
		texte.x = 8;
		texte.y = 8;
		this.addChild(texte);

		i = new h2d.Interactive(width, height, this);
		
		game.boardUi.addChild(this);
	}
	
}