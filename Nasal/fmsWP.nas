#
#   FMS STAR/SID database class
#
#
#   Copyright (C) 2009 Scott Hamilton
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

var fmsWP = {
    new : func{
        var me = {parents:[fmsWP]};

        me.wp_name = "";
        me.wp_type = "FIX";   # FIX, NAVAID, Termination Point, transition wp, Final Fix, Appr Fix, RWY transition
        me.action  = "DIRECT";  # direct, trk, intercept, vectors
        me.wp_lat  = 0.0;       # only if not a known fix/navaid
        me.wp_lon  = 0.0;       # only if not a known fix/navaid
        me.alt_csrt = 0;       # alt constrain in ft
        me.spd_csrt = 0;       # spd constrain in kts
        me.hdg_radial = 0.0;   # either heading/track or radial

        return me;
    },

}