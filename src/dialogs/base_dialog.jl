# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Description
# ==============================================================================
#
#   Create a generic dialog.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

export create_dialog

function create_dialog(f_widgets::Function,
                       buttons::AbstractVector{String};
                       title::AbstractString = " Dialog ",
                       border_color::Int = -1,
                       text_color::Int = -1,
                       title_color::Int = -1,
                       height::Int = 10,
                       width::Int = 80)

    # Create a new window with a container in the middle of the root window.
    opc = newopc(anchor_center = Anchor(:parent, :center, 0),
                 anchor_middle = Anchor(:parent, :middle, 0),
                 height        = height,
                 width         = width)

    w = create_window(opc,
                      border = true,
                      title = title,
                      border_color = border_color,
                      title_color = title_color)

    opc_c = newopc(anchor_top    = Anchor(:parent, :top,    0),
                   anchor_left   = Anchor(:parent, :left,   1),
                   anchor_right  = Anchor(:parent, :right, -1),
                   anchor_bottom = Anchor(:parent, :bottom, 0))

    c = create_widget(Val(:container), opc_c)

    add_widget!(w, c)

    # Call the function to create the widgets.
    f_widgets(c)

    # Function to be called when a keystroke is pressed on a button.
    terminate = false
    button_id = 0

    # Function to be called when a key is pressed in a button.
    function _button_on_keypressed(widget, k, b_id)
        if k.ktype == :enter
            terminate = true
            button_id = b_id
            return false
        end

        return true
    end

    num_buttons = length(buttons)
    last_button = nothing

    c_button = ncurses_color(NCurses.A_REVERSE)

    for k = num_buttons:-1:1
        anchor_right = (k == num_buttons) ? Anchor(:parent,     :right,  0) :
                                            Anchor(last_button, :left,  -1)
        opc_b = newopc(anchor_right  = anchor_right,
                       anchor_bottom = Anchor(:parent, :bottom, 0))

        last_button = create_widget(Val(:button), opc_b;
                                    color_highlight = c_button,
                                    label = buttons[k])
        add_widget!(c, last_button)

        @connect_signal last_button key_pressed _button_on_keypressed k
    end

    # Change the focus to the new window.
    old_win = get_focused_window()
    request_focus(w)
    request_next_widget(c)

    # Get the focus until one of the buttons is pressed.
    while !terminate
        ch = jlgetch()
        process_focus(ch)
    end

    # Destroy the dialog and return the focus to the previous window.
    destroy_window!(w)
    request_focus(old_win)

    return button_id
end
