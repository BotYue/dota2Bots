

----------------------------------------------------------------------------------------------------
offset = 0;
function Think()


	if ( GetTeam() == TEAM_RADIANT )
	then
		print( "selecting radiant" );
		SelectHero( 0 + offset, "npc_dota_hero_antimage" );
		SelectHero( 1 + offset, "npc_dota_hero_drow_ranger" );
		SelectHero( 2 + offset, "npc_dota_hero_sven" );
		SelectHero( 3 + offset, "npc_dota_hero_undying" );
		SelectHero( 4 + offset, "npc_dota_hero_crystal_maiden" );
	elseif ( GetTeam() == TEAM_DIRE )
	then
		print( "selecting dire" );
		SelectHero( 5 + offset, "npc_dota_hero_lina" );
		SelectHero( 6 + offset, "npc_dota_hero_zuus" );
		SelectHero( 7 + offset, "npc_dota_hero_mirana" );
		SelectHero( 8 + offset, "npc_dota_hero_shredder" );
		SelectHero( 9 + offset, "npc_dota_hero_tinker" );
	end

end

----------------------------------------------------------------------------------------------------
