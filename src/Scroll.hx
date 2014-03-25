import Common;

class Scroll
{
	static public var ZOOM = 0;
	
	public static function mapWidth() { return Const.MAP_WIDTH * (1 + 0.1 * ZOOM); }
	public static function mapHeight() { return Const.MAP_HEIGHT * (1 + 0.1 * ZOOM); }
	
	public function new () {
		var game = Game.inst;
		game.boardBackground.scaleX = game.board.scaleX = 1 + 0.1 * ZOOM; 
		game.boardBackground.scaleY = game.board.scaleY = 1 + 0.1 * ZOOM; 		
	}
	
	public static function updateScroll(liste = null) {
		var game = Game.inst;
		if( liste != null) {
			if (liste.up) game.boardBackground.y = game.board.y = game.board.y + 10;
			if (liste.down) game.board.y = game.boardBackground.y = game.board.y - 10;
			if (liste.left) game.boardBackground.x = game.board.x = game.board.x + 10;
			if (liste.right) game.boardBackground.x = game.board.x = game.board.x - 10;
		}
		
		if (game.board.x > 0 ) game.boardBackground.x = game.board.x = 0;
		if (game.board.x <= -Scroll.mapWidth() + Const.MAP_WIDTH ) game.boardBackground.x = game.board.x = -Scroll.mapWidth() + Const.MAP_WIDTH;
		if (game.board.y >= 0 ) game.boardBackground.y = game.board.y = 0;
		if (game.board.y <= -Scroll.mapHeight() + Const.MAP_HEIGHT ) game.board.y = game.boardBackground.y = -Scroll.mapHeight() + Const.MAP_HEIGHT;
	}
	
	public static function wheel (e:hxd.Event) {
		var game = Game.inst;
		
		var realx = mapWidth() * (e.relX / Const.MAP_WIDTH) + game.board.x;
		var realy = mapHeight() * (e.relY / Const.MAP_HEIGHT) + game.board.y;

		if (e.wheelDelta == -1 && ZOOM < 20) ZOOM += 2 ;
		else if (e.wheelDelta == 1 && ZOOM > 0) ZOOM -= 2;
		
		game.boardBackground.scaleX = game.board.scaleX = 1 + 0.1 * ZOOM; 
		game.boardBackground.scaleY = game.board.scaleY = 1 + 0.1 * ZOOM; 
		
		game.boardBackground.x = game.board.x = realx - mapWidth() * (e.relX / Const.MAP_WIDTH);
		game.boardBackground.y = game.board.y = realy - mapHeight() * (e.relY / Const.MAP_HEIGHT);
		
		updateScroll();
	}
	
}