# DUKit
A collection of utilities and functionality to help write Dual Universe lua scripts.

To use simply create a new start filter in the system slot and past the contents of DUKit there. DUKit will then be available to all filters loaded after it.

• Implements filtered console output. You can set the CONSOLE_LOUDNESS variable to QUIET, ERRORS, WARNINGS, or DEBUG. Calling the corresponding
functions (debug(msg), warn(msg), err(msg)) then outputs the message based on the currently set filter. This helps to reduce the noise in the
lua console once debugging is finished, showing only warnings or errors to the users.

• Implements slot unit detection with the function autoDetectSlots(). This walks the unit table and finds slot unit entries and adds them (if they
supported by DUKit) to the corresponding unit list. For example lights will be added to the light table, screens will be added to the screen table
and so on, in the order that they were added.

• Implements basic support functionality for doors, lights, screens and signs.

• Implements color conversion and manipulation support.

• Implements helper functionality for tables.

The ScreenExample.config shows how to set content on one or more screens.
![](https://github.com/Dahvram/DUKit/blob/main/ScreenExample.png)

Send and questions or recomendations to me at my email address or discord id.
