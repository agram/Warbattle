import Common;

class MapGame
{
	public var width:Int;
	public var height:Int;
	public var game:Game;
	
	public function new() {
		game = Game.inst;
		
		var t1 = Res.tileset_7.toTile();
		var tiles1 = [for ( y in 0...t1.height >> 4 ) for ( x in 0...t1.width >> 4 ) t1.sub(x * 16, y * 16, 16, 16)];
		var t2 = Res.forest_tileset.toTile();
		var tiles2 = [for ( y in 0...t2.height >> 4 ) for ( x in 0...t2.width >> 4 ) t2.sub(x * 16, y * 16, 16, 16)];		var map = Res.load("Map.tmx").toTiledMap().toMap();
			
		var tiles = tiles1.concat(tiles2);
		
		width = map.width;
		height = map.height;

		var g1 = new h2d.TileGroup(t1);
		var g2 = new h2d.TileGroup(t2);
		var g3 = new h2d.TileGroup(t2);
		
		for ( numL in 0...2 ) {
			var l = map.layers[numL];
			var pos = 0;

			g1.alpha = l.opacity;
			g2.alpha = l.opacity;
			
			for ( y in 0...height ) {
				var yy = y * 16;
				for( x in 0...width ) {
					var xx = x * 16;
					var t = l.data[pos++] - 1;
					if ( t < 0 ) continue;
					if(numL == 0 ) {
						g1.add(xx, yy, tiles[t]);
						
						switch(t) {
						case 0, 1, 2, 3, 4, 12, 13, 
							16, 18, 19, 20, 28, 29, 
							32, 33, 34, 35, 
							42, 43, 44, 45, 46, 47, 
							58, 60, 61, 62, 64,
							72, 73, 74, 75, 76, 77, 78, 79, 
							88, 89 :
								var a = xx + Const.MAP_WIDTH * yy;
								for (i in 0...16) {
									for (j in 0...16) {
										var b = Std.int(a + i + Const.MAP_WIDTH * j);
										game.player.obstacle[b] = -2;
										game.opponent.obstacle[b] = -2;
									}
								}		

						default:
						}
					}
					else {
						var b = t - tiles1.length;
						if( b >= 70 && b < 75)
							g2.add(xx, yy, tiles[t]);
						else 
							g3.add(xx, yy, tiles[t]);
						
						var value = 
							switch(t - tiles1.length) {
							case 15, 16, 17, 18 : -1;
							case 0, 5, 28, 33 : 0;
							default: -3;
							}
						
						var a = xx + Const.MAP_WIDTH * yy;
						for (i in 0...16) {
							for (j in 0...16) {
								var b = Std.int(a + i + Const.MAP_WIDTH * j);
								game.player.obstacle[b] = value;
								game.opponent.obstacle[b] = value;
							}
						}		
					}
				}
			}
		}
		game.boardBackground.add(g1, 1);
		game.board.add(g2, Const.L_GROUND);
		game.board.add(g3, Const.L_UP);
		
	}
}