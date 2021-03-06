package away3d.tools
{
	import away3d.arcane;
	import away3d.containers.ObjectContainer3D;
	import away3d.core.base.Geometry;
	import away3d.core.base.SubGeometry;
	import away3d.core.base.data.UV;
	import away3d.core.base.data.Vertex;
	import away3d.entities.Mesh;

	use namespace arcane;
	
	/**
	* Class Weld removes the vertices that can be shared<code>Weld</code>
	*/
	public class Weld{
		
		private static var _delv:uint;
		private static const LIMIT:uint = 64998;

		/**
		*  Apply the welding code to a given ObjectContainer3D.
		* @param	 object		ObjectContainer3D. The target Object3d object.
		*/
		public static function apply(object:ObjectContainer3D):void
		{
			_delv = 0;
			parse(object);
		}
		
		/**
		* returns howmany vertices were deleted during the welding operation.
		*/
		public static function get verticesRemoved():uint
		{
			return _delv;
		}
		 
		private static function parse(object:ObjectContainer3D):void
		{
			var child:ObjectContainer3D;
			if(object is Mesh && object.numChildren == 0)
				weld(Mesh(object));
				 
			for(var i:uint = 0;i<object.numChildren;++i){
				child = object.getChildAt(i);
				parse(child);
			}
		}
		
		private static function checkEntry(v:Vertex, uv:UV, vertices:Vector.<Number>, indices:Vector.<uint>, uvs:Vector.<Number>):int
		{
			
			var ind:uint = 0;
			for(var i:uint = 0;i<vertices.length;i+=3){
				
				if(v.x == vertices[i]){					
					if(v.y == vertices[i+1] && v.z == vertices[i+2] && uv.u == uvs[ind*2] && uv.v == uvs[(ind*2)+1]){
						_delv++;
						return indices[ind];
					}
				}
				
				ind++;
			}
			 
			return -1;
		}
		
		private static function weld(m:Mesh):void
		{
			var geometry:Geometry = m.geometry;
			var geometries:Vector.<SubGeometry> = geometry.subGeometries;
			var numSubGeoms:int = geometries.length;
			
			var vertices:Vector.<Number>;
			var indices:Vector.<uint>;
			var uvs:Vector.<Number>;
			
			var v:Vertex = new Vertex();
			var uv:UV = new UV();
			
			var nvertices:Vector.<Number> = new Vector.<Number>();
			var nindices:Vector.<uint> = new Vector.<uint>();
			var nuvs:Vector.<Number> =new Vector.<Number>();
			
			var vectors:Array = [];
			vectors.push(nvertices,nindices,nuvs);
			 
			var index:uint;
			var indexuv:uint;
			var indexind:uint;
			
			var nIndex:uint = 0;
			var nIndexuv:uint = 0;
			var nIndexind:uint = 0;
			var checkIndex:int;
			
			var j : uint;
			var i : uint;
			var vecLength : uint;
			var subGeom:SubGeometry;
			 
			for (i = 0; i < numSubGeoms; ++i){
				subGeom = SubGeometry(geometries[i]);
				vertices = subGeom.vertexData;
				indices = subGeom.indexData;
				uvs = subGeom.UVData;
				vecLength = indices.length;

				for (j = 0; j < vecLength;++j){
					index = indices[j]*3;
					indexuv = indices[j]*2;
					v.x = vertices[index];
					v.y = vertices[index+1];
					v.z = vertices[index+2];
					uv.u = uvs[indexuv];
					uv.v = uvs[indexuv+1];
					 
					checkIndex = checkEntry(v, uv, nvertices, nindices, nuvs);

					if( checkIndex == -1){
						if(nvertices.length+3 > LIMIT){
							nIndexind = 0;
							nIndex = 0;
							nIndexuv = 0;
							nvertices = new Vector.<Number>();
							nindices = new Vector.<uint>();
							nuvs =new Vector.<Number>();
							vectors.push(nvertices,nindices,nuvs);
						}
						
						nindices[nIndexind++] = nvertices.length/3;
						nvertices[nIndex++] = v.x;
						nvertices[nIndex++] = v.y;
						nvertices[nIndex++] = v.z;
						nuvs[nIndexuv++] = uv.u;
						nuvs[nIndexuv++] = uv.v;
						 
					} else {
						nindices[nIndexind++] = checkIndex;
					}
						
				}
			}
			 
			if(numSubGeoms> 1){
				throw new Error("line 186: Weld : multiple subgeometries not implemented yet");
				for (i = 1; i < numSubGeoms; ++i){
					//not implemented yet
					//geometry.removeSubGeometry(geometry.subGeometries[i]);
				}
			}
			
			// here when above is active, set i to 1
			for (i = 0; i<vectors.length; i+=3){
				if(i>0){
					subGeom = new SubGeometry();
					geometry.addSubGeometry(subGeom);
				} else{
					subGeom = SubGeometry(geometries[i]);
				}
				subGeom.updateVertexData(vectors[i]);
				subGeom.updateIndexData(vectors[i+1]);
				subGeom.updateUVData(vectors[i+2]);
			}
			 
			vectors = null;
		}
		 
	}
}