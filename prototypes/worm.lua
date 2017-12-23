require "worm-animations"
require "worm-sounds"

huge_worm_scale = 1.3
huge_worm_tint = {r=0.3, g=0.9, b=0.3, a=1.0}

data:extend(
{
  {
    type = "turret",
    name = "behemoth-worm-turret",
    icon = "__Oreverhaul__/graphics/icons/huge-worm.png",
	icon_size = 32,
    flags = {"placeable-player", "placeable-enemy", "not-repairable", "breaths-air"},
    max_health = 5000,
    order="b-b-f",
    subgroup="enemies",
    resistances =
    {
      {
        type = "physical",
        decrease = 16,
      },
      {
        type = "explosion",
        decrease = 20,
        percent = 50,
      }
    },
	localised_name = "Behemoth Worm",
    healing_per_tick = 0.03,
    collision_box = {{-1.8, -1.6}, {1.8, 1.6}},
    selection_box = {{-1.8, -1.6}, {1.8, 1.6}},
    shooting_cursor_size = 4,
    rotation_speed = 1,
    corpse = "huge-worm-corpse",
    dying_explosion = "blood-explosion-big",
    dying_sound = make_worm_dying_sounds(1.0),
    inventory_size = 2,
    folded_speed = 0.01,
    folded_animation = worm_folded_animation(huge_worm_scale, huge_worm_tint),
    --prepare_range = 30, why is this here twice?
    preparing_speed = 0.025,
    preparing_animation = worm_preparing_animation(huge_worm_scale, huge_worm_tint, "forward"),
    prepared_speed = 0.015,
    prepared_animation = worm_prepared_animation(huge_worm_scale, huge_worm_tint),
    starting_attack_speed = 0.03,
    starting_attack_animation = worm_attack_animation(huge_worm_scale, huge_worm_tint, "forward"),
    starting_attack_sound = make_worm_roars(0.95),
    ending_attack_speed = 0.03,
    ending_attack_animation = worm_attack_animation(huge_worm_scale, huge_worm_tint, "backward"),
    folding_speed = 0.015,
    folding_animation = worm_preparing_animation(huge_worm_scale, huge_worm_tint, "backward"),
    prepare_range = 35,
    attack_parameters =
    {
      type = "projectile",
      ammo_category = "rocket",
      cooldown = 100,
      range = 30,
      projectile_creation_distance = 2.3,
      damage_modifier = 20,
      ammo_type =
      {
        category = "biological",
        action =
        {
          type = "direct",
          action_delivery =
          {
            type = "projectile",
            projectile = "acid-projectile-purple",
            starting_speed = 0.5
          }
        }
      }
    },
	build_base_evolution_requirement = 0.9,
    call_for_help_radius = 40
	},
  {
    type = "corpse",
    name = "huge-worm-corpse",
    icon = "__Oreverhaul__/graphics/icons/huge-worm-corpse.png",
	icon_size = 32,
    selection_box = {{-1, -1}, {1, 1}},
    selectable_in_game = false,
    subgroup="corpses",
    order = "c[corpse]-c[worm]-c[big]",
    flags = {"placeable-neutral", "placeable-off-grid", "building-direction-8-way", "not-repairable", "not-on-map"},
    dying_speed = 0.01,
    time_before_removed = 15 * 60 * 60,
    final_render_layer = "corpse",
    animation = worm_die_animation(huge_worm_scale, huge_worm_tint)
  }
}
)