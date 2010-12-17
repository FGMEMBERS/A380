#
#   Simple utility to manage an array of text lines in a region.
#
#
#   Copyright (C) 2009 Scott Hamilton
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

var TextRegion = {
    new : func(lines, width, prefix){
        var me = {parents:[TextRegion]};

        me.posLine = 0;
	me.baseNode = props.globals.getNode(prefix,1);
        me.maxWidth = width;
        me.maxLines = lines;
        for(var p = 0; p != lines; p=p+1) {
          var lineNode = me.baseNode.getNode("line["~p~"]",1);
          lineNode.setValue("");
        }

        return me;
    },


   append : func(text) {
    var lineNode = me.baseNode.getNode("line["~me.posLine~"]",1);
    lineNode.setValue(text);
    if (me.posLine < me.maxLines) {
      me.posLine = me.posLine+1;
    }
   },

   textAt : func(index, text) {
     var lineNode = me.baseNode.getNode("line["~index~"]",1);
     lineNode.setValue(text);
     me.posLine = index;
   },

   clear : func() {
     for(var p = 0; p != me.maxLines; p=p+1) {
          var lineNode = me.baseNode.getNode("line["~p~"]",1);
          lineNode.setValue("");
     }
     me.posLine = 0;
   },

   reset : func() {
     for(var p = me.posLine; p != me.maxLines; p=p+1) {
       var lineNode = me.baseNode.getNode("line["~p~"]",1);
       lineNode.setValue("");
     }
     me.posLine = 0;
   }
}