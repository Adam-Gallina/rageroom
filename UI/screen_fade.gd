extends AnimationPlayer
class_name ScreenFade

var faded = false

func fade_in(duration:float = .2):
    if not faded: return true

    speed_scale = 1. / duration
    play('fade_in')

    faded = false

    await animation_finished
    return true

func fade_out(duration:float = .2):
    if faded: return true

    speed_scale = 1. / duration
    play('fade_out')
    
    faded = true

    await animation_finished
    return true