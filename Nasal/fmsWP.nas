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
    new : func {
        var me = {parents:[fmsWP]};

        me.wp_name = "";
        me.wp_parent_name = "";   # if a SID/STAR WP then the SID/STAR name
        me.wp_type = "FIX";   # FIX, NAVAID, Termination Point, transition wp, Final Fix, Appr Fix, RWY transition, SID/STAR WP
        me.fly_type = "FlyOver";  # flyOver, flyBy, Hold, 
        me.action  = "DIRECT";  # direct, trk, intercept, vectors
        me.wp_lat  = 0.0;       # only if not a known fix/navaid
        me.wp_lon  = 0.0;       # only if not a known fix/navaid
        me.alt_csrt = 0;       # alt constrain in ft
        me.spd_csrt = 0;       # spd constrain in kts
        me.hdg_radial = 0.0;   # either heading/track or radial
        me.leg_distance = 0;   # NM for this leg
        me.leg_bearing  = 0.0; # deg bearing for this leg

        return me;
    },

}