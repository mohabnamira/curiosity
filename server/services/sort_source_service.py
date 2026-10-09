from typing import List
from sentence_transformers import SentenceTransformer
import numpy as np


class SortSourceService:
    def __init__(self):
        self.embedding_model = SentenceTransformer('all-MiniLM-L6-v2')

    def sort_sources(self, query: str,search_results: list[dict]):
        relevance_docs = []
        query_embedding = self.embedding_model.encode([query])
        for result in search_results:
            result_embedding = self.embedding_model.encode([result['content']])
            similarity = np.dot(query_embedding,result_embedding)/(
                np.linalg.norm(query_embedding)*np.linalg.norm(result_embedding)
                )
            result['relevance'] = similarity
            if similarity > 0.3:
                relevance_docs.append(result)
        sorted_results = sorted(relevance_docs, key=lambda x: x['relevance'], reverse=True)
        return sorted_results

        